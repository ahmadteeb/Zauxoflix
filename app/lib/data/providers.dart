import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/app_database.dart';
import 'resume/resume_service.dart';
import 'sync/catalog_sync_service.dart';
import 'xtream/xtream_api.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// v1 is single-source: the first configured playlist is the active one.
final activeSourceProvider = StreamProvider<Source?>(
  (ref) => ref.watch(databaseProvider).watchActiveSource(),
);

final xtreamApiProvider = Provider<XtreamApi?>((ref) {
  final source = ref.watch(activeSourceProvider).value;
  if (source == null || source.sourceType != SourceType.xtream) return null;
  return XtreamApi(
    XtreamCredentials(
      serverUrl: source.serverUrl,
      username: source.username,
      password: source.password,
    ),
  );
});

/// Resolves playback URLs for both source types: M3U rows carry their own
/// URL, Xtream rows build one from credentials.
class PlaybackUrls {
  const PlaybackUrls(this._api);

  final XtreamApi? _api;

  String? live(LiveChannel c) => c.streamUrl ?? _api?.liveStreamUrl(c.streamId);

  String? movie(Movie m, {String? containerExtension}) =>
      m.streamUrl ??
      _api?.movieUrl(m.streamId, containerExtension ?? m.containerExtension);

  String? episode(int episodeId, String? containerExtension) =>
      _api?.seriesEpisodeUrl(episodeId, containerExtension);
}

final playbackUrlsProvider = Provider<PlaybackUrls?>((ref) {
  if (ref.watch(activeSourceProvider).value == null) return null;
  return PlaybackUrls(ref.watch(xtreamApiProvider));
});

final resumeServiceProvider = Provider<ResumeService?>((ref) {
  final source = ref.watch(activeSourceProvider).value;
  if (source == null) return null;
  return ResumeService(ref.watch(databaseProvider), source.id);
});

/// Currently-airing programme per (lowercased) EPG channel id, refreshed
/// once a minute and after every sync. autoDispose so the poll stops when the
/// Live tab isn't listening (see LiveTvScreen's visibility gate).
final nowPlayingProvider =
    StreamProvider.autoDispose<Map<String, EpgProgramme>>((ref) {
      final db = ref.watch(databaseProvider);
      final source = ref.watch(activeSourceProvider).value;
      ref.watch(syncControllerProvider);
      if (source == null) return Stream.value(const {});
      final updates = StreamController<Map<String, EpgProgramme>>();
      var loading = false;
      Future<void> refresh() async {
        if (loading || updates.isClosed) return;
        loading = true;
        try {
          final data = await db.nowPlaying(source.id, DateTime.now());
          if (!updates.isClosed) updates.add(data);
        } catch (error, stack) {
          if (!updates.isClosed) updates.addError(error, stack);
        } finally {
          loading = false;
        }
      }

      final timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => unawaited(refresh()),
      );
      ref.onDispose(() {
        timer.cancel();
        unawaited(updates.close());
      });
      unawaited(refresh());
      return updates.stream;
    });

sealed class SyncState {
  const SyncState();
}

class SyncIdle extends SyncState {
  const SyncIdle();
}

class SyncRunning extends SyncState {
  const SyncRunning(this.stage);
  final String stage;
}

class SyncFailure extends SyncState {
  const SyncFailure(this.message);
  final String message;
}

class SyncSuccess extends SyncState {
  const SyncSuccess();
}

final syncControllerProvider = NotifierProvider<SyncController, SyncState>(
  SyncController.new,
);

class SyncController extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncIdle();

  Future<bool> syncSource(Source source) async {
    if (state is SyncRunning) return false;
    state = const SyncRunning('Connecting…');
    try {
      final service = CatalogSyncService(ref.read(databaseProvider));
      await service.syncAll(
        source,
        onStage: (stage) => state = SyncRunning(stage),
      );
      state = const SyncSuccess();
      return true;
    } catch (e) {
      state = SyncFailure(syncErrorMessage(e));
      return false;
    }
  }
}
