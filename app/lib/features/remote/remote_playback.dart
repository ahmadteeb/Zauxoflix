import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../../data/xtream/xtream_models.dart';
import '../player/player_screen.dart';

/// The local player's hooks for remotely-issued transport commands, plus the
/// status snapshot it exposes to the account's other devices. Implemented by
/// [PlayerScreen]'s state and attached while a player is on screen.
abstract class RemotePlayerHandle {
  RemotePlayerSnapshot remoteSnapshot();
  void remotePause();
  void remoteResume();
  void remoteSeek(Duration position);
  void remoteNext();
  void remotePrev();
  void remoteStop();
}

class RemotePlayerSnapshot {
  const RemotePlayerSnapshot({
    required this.state,
    this.identity,
    this.title = '',
    this.subtitle = '',
    this.positionSec = 0,
    this.durationSec = 0,
    this.hasPrev = false,
    this.hasNext = false,
  });

  /// loading | playing | paused | idle.
  final String state;
  final PlaybackIdentity? identity;
  final String title;
  final String subtitle;
  final int positionSec;
  final int durationSec;
  final bool hasPrev;
  final bool hasNext;
}

/// Executes playback commands relayed from the account's other devices
/// (open content, transport) and reports this device's player state back
/// through the backend. Kept alive by the app root.
final remotePlaybackProvider = NotifierProvider<RemotePlaybackController, void>(
  RemotePlaybackController.new,
);

class RemotePlaybackController extends Notifier<void> {
  RemotePlayerHandle? _handle;
  Timer? _reportTimer;
  String? _lastReportKey;

  static const _reportInterval = Duration(seconds: 5);

  @override
  void build() {
    final subscription = ref
        .read(remoteCommandsProvider)
        .stream
        .listen(_onCommand);
    ref.onDispose(subscription.cancel);
    ref.onDispose(() => _reportTimer?.cancel());
  }

  void attachPlayer(RemotePlayerHandle handle) {
    _handle = handle;
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(_reportInterval, (_) => _report(force: true));
    _report(force: true);
  }

  /// The old player's dispose can land after a replacement already attached,
  /// so only the current handle detaches.
  void detachPlayer(RemotePlayerHandle handle) {
    if (_handle != handle) return;
    _handle = null;
    _reportTimer?.cancel();
    _reportTimer = null;
    _lastReportKey = null;
    _send(const RemotePlayerSnapshot(state: 'idle'));
  }

  /// Called on every player value tick; deduped so only material transitions
  /// (play/pause/item switch) go out immediately — positions ride the timer.
  void playerChanged() => _report(force: false);

  void _report({required bool force}) {
    final snapshot = _handle?.remoteSnapshot();
    if (snapshot == null) return;
    final key =
        '${snapshot.state}|${snapshot.title}|${snapshot.subtitle}'
        '|${snapshot.hasPrev}|${snapshot.hasNext}';
    if (!force && key == _lastReportKey) return;
    _lastReportKey = key;
    _send(snapshot);
  }

  void _send(RemotePlayerSnapshot snapshot) {
    if (ref.read(authControllerProvider) is! Authenticated) return;
    unawaited(
      ref
          .read(remoteRepositoryProvider)
          .reportStatus(
            RemoteStatus(
              deviceId: ref.read(deviceIdentityProvider).deviceId,
              state: snapshot.state,
              identity: snapshot.identity,
              title: snapshot.title,
              subtitle: snapshot.subtitle,
              positionSec: snapshot.positionSec,
              durationSec: snapshot.durationSec,
              hasPrev: snapshot.hasPrev,
              hasNext: snapshot.hasNext,
            ),
          ),
    );
  }

  Future<void> _onCommand(RemoteCommand command) async {
    switch (command.action) {
      case 'play':
        await _play(command);
      case 'pause':
        _handle?.remotePause();
      case 'resume':
        _handle?.remoteResume();
      case 'seek':
        _handle?.remoteSeek(Duration(seconds: command.positionSec));
      case 'next':
        _handle?.remoteNext();
      case 'prev':
        _handle?.remotePrev();
      case 'stop':
        _handle?.remoteStop();
    }
  }

  Future<void> _play(RemoteCommand command) async {
    final args = await _resolve(command);
    final context = rootNavigatorKey.currentContext;
    if (args == null || context == null || !context.mounted) return;
    // Replace whatever is playing: pop the live player first, then push the
    // new one. The old screen's late dispose is handled by detachPlayer's
    // handle check.
    _handle?.remoteStop();
    unawaited(context.push('/player', extra: args));
  }

  /// Resolves the commanded item in this device's own synced catalog and
  /// builds the same [PlayerArgs] the detail screens would, so resume
  /// reporting and binge flow behave identically to a local start.
  Future<PlayerArgs?> _resolve(RemoteCommand command) async {
    final identity = command.identity!;
    final id = int.tryParse(identity.itemId);
    final db = ref.read(databaseProvider);
    final source = await db.watchActiveSource().first;
    final urls = ref.read(playbackUrlsProvider);
    if (id == null || source == null || urls == null) return null;
    final resume = ref.read(resumeServiceProvider);
    final startAt = command.positionSec > 0
        ? Duration(seconds: command.positionSec)
        : null;

    switch (identity.itemType) {
      case 'MOVIE':
        final movie = await db.getMovie(source.id, id);
        final url = movie == null ? null : urls.movie(movie);
        if (movie == null || url == null) return null;
        return PlayerArgs.single(
          url: url,
          title: movie.name,
          startAt: startAt,
          identity: identity,
          onProgress: (_, position, duration) => resume?.report(
            kind: WatchKind.movie,
            itemId: id,
            title: movie.name,
            imageUrl: movie.icon,
            containerExtension: movie.containerExtension,
            position: position,
            duration: duration,
          ),
        );

      case 'LIVE':
        final channel = await db.getLiveChannel(source.id, id);
        final url = channel == null ? null : urls.live(channel);
        if (channel == null || url == null) return null;
        return PlayerArgs.single(
          url: url,
          title: channel.name,
          live: true,
          liveLogo: channel.icon,
          identity: identity,
        );

      case 'SERIES':
        final episodeId = int.tryParse(identity.episodeId ?? '');
        final api = ref.read(xtreamApiProvider);
        if (episodeId == null || api == null) return null;
        final series = await db.getSeriesItem(source.id, id);
        if (series == null) return null;
        final XtreamSeriesInfo info;
        try {
          info = await api.seriesInfo(id);
        } catch (_) {
          return null;
        }
        List<XtreamEpisode>? episodes;
        var index = 0;
        for (final seasonEpisodes in info.seasons.values) {
          final i = seasonEpisodes.indexWhere((e) => e.id == episodeId);
          if (i >= 0) {
            episodes = seasonEpisodes;
            index = i;
            break;
          }
        }
        if (episodes == null) return null;
        final playlist = episodes;
        return PlayerArgs(
          items: [
            for (final (i, e) in playlist.indexed)
              PlayerItem(
                url: api.seriesEpisodeUrl(e.id, e.containerExtension),
                title: series.name,
                episodeImage: e.image,
                seriesCover: series.cover,
                containerExtension: e.containerExtension,
                subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
                startAt: i == index ? startAt : null,
                identity: PlaybackIdentity(
                  itemType: 'SERIES',
                  itemId: identity.itemId,
                  episodeId: '${e.id}',
                ),
              ),
          ],
          initialIndex: index,
          onProgress: (i, position, duration) {
            final e = playlist[i];
            resume?.report(
              kind: WatchKind.episode,
              itemId: e.id,
              seriesId: id,
              title: series.name,
              subtitle: 'S${e.season} E${e.episodeNum} — ${e.title}',
              imageUrl: series.cover ?? e.image,
              containerExtension: e.containerExtension,
              position: position,
              duration: duration,
            );
          },
        );
    }
    return null;
  }
}
