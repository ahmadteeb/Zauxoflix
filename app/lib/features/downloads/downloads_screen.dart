import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/media_artwork.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/downloads/download_preferences.dart';
import '../../data/providers.dart';
import '../player/player_screen.dart';
import '../remote/cast_session.dart';
import '../shell/top_nav_bar.dart';
import 'download_actions.dart';
import 'download_nav_icon.dart';
import 'download_network_setting.dart';
import 'download_progress_details.dart';

final _watchedDownloadsProvider = StreamProvider.autoDispose
    .family<List<DownloadItem>, int>((ref, sourceId) {
      return ref.watch(databaseProvider).watchWatchedDownloads(sourceId);
    });

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = formFactorOf(context, ref);
    final mobile = form == FormFactor.mobile;
    final source = ref.watch(activeSourceProvider);
    final sourceId = source.value?.id;
    final AsyncValue<List<DownloadItem>?> state = sourceId == null
        ? source.whenData((_) => null)
        : ref.watch(downloadsForSourceProvider(sourceId));
    final items = state.asData?.value;
    final saved = items?.where((item) => item.status == DownloadStatus.done);
    final transfers = items?.where(
      (item) => item.status != DownloadStatus.done,
    );
    final bytes = saved?.fold<int>(
      0,
      (sum, item) => sum + (item.totalBytes ?? 0),
    );
    final watched = sourceId == null
        ? null
        : ref.watch(_watchedDownloadsProvider(sourceId)).value;

    return Padding(
      padding: EdgeInsets.only(top: mobile ? 0 : kTopNavHeight),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            key: ValueKey(sourceId),
            padding: EdgeInsets.fromLTRB(
              form.gutter,
              mobile ? 20 : 30,
              form.gutter,
              32,
            ),
            children: [
              _DownloadsHeader(saved: saved?.length, bytes: bytes),
              if (supportsMobileDownloads && !form.isTv) ...[
                const SizedBox(height: 12),
                const _DownloadSurface(child: DownloadNetworkSetting()),
              ],
              const SizedBox(height: 24),
              if (state.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (state.hasError)
                _DownloadsMessage(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load downloads',
                  action: OutlinedButton(
                    onPressed: () {
                      if (sourceId == null) {
                        ref.invalidate(activeSourceProvider);
                      } else {
                        ref.invalidate(downloadsForSourceProvider(sourceId));
                      }
                    },
                    child: const Text('Try again'),
                  ),
                )
              else if (items == null)
                const _DownloadsMessage(
                  icon: Icons.playlist_add_rounded,
                  title: 'No playlist configured',
                )
              else if (items.isEmpty)
                _DownloadsMessage(
                  icon: Icons.download_for_offline_outlined,
                  title: 'No downloads yet',
                  body:
                      'Use the download button on a movie or episode to watch it offline.',
                  action: OutlinedButton(
                    onPressed: () => context.go('/movies'),
                    child: const Text('Browse movies'),
                  ),
                )
              else ...[
                if (transfers!.isNotEmpty)
                  _DownloadSection(
                    title: 'Transfers',
                    items: transfers,
                    compact: mobile,
                  ),
                if (saved!.isNotEmpty)
                  _DownloadSection(
                    title: 'On this device',
                    items: saved,
                    compact: mobile,
                    action: watched?.isNotEmpty == true
                        ? OutlinedButton.icon(
                            onPressed: () => confirmWatchedDownloadRemoval(
                              context,
                              ref,
                              watched!,
                            ),
                            icon: const Icon(
                              Icons.cleaning_services_outlined,
                              size: 18,
                            ),
                            label: const Text('Remove watched episodes'),
                          )
                        : null,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadsHeader extends StatelessWidget {
  const _DownloadsHeader({required this.saved, required this.bytes});

  final int? saved;
  final int? bytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final caption = switch (saved) {
      null => 'Watch saved movies and episodes offline',
      1 => '1 file saved',
      _ => '$saved files saved',
    };
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.download_for_offline_rounded,
                color: AppColors.error,
                size: 30,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Downloads',
                  style: theme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                caption,
                style: theme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if ((bytes ?? 0) > 0)
                Text(
                  '${downloadSize(bytes!)} on this device',
                  style: theme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DownloadsMessage extends StatelessWidget {
  const _DownloadsMessage({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      children: [
        Icon(icon, size: 36, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (body != null) ...[
          const SizedBox(height: 8),
          Text(
            body!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class _DownloadSection extends StatelessWidget {
  const _DownloadSection({
    required this.title,
    required this.items,
    required this.compact,
    this.action,
  });

  final String title;
  final Iterable<DownloadItem> items;
  final bool compact;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    // A series takes the position of its most recent download.
    final series = <int, List<DownloadItem>>{};
    final entries = <List<DownloadItem>>[];
    for (final item in items) {
      final seriesId = item.seriesId;
      if (item.kind != WatchKind.episode || seriesId == null) {
        entries.add([item]);
      } else {
        series
            .putIfAbsent(seriesId, () {
              final group = <DownloadItem>[];
              entries.add(group);
              return group;
            })
            .add(item);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  entry.first.kind == WatchKind.episode &&
                      entry.first.seriesId != null
                  ? _SeriesDownloads(
                      key: ValueKey(entry.first.seriesId),
                      episodes: entry,
                      compact: compact,
                    )
                  : _DownloadSurface(
                      child: _DownloadRow(
                        key: ValueKey((entry.first.kind, entry.first.itemId)),
                        item: entry.first,
                        compact: compact,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _DownloadSurface extends StatelessWidget {
  const _DownloadSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    clipBehavior: Clip.antiAlias,
    borderRadius: BorderRadius.circular(16),
    child: child,
  );
}

class _SeriesDownloads extends StatelessWidget {
  const _SeriesDownloads({
    super.key,
    required this.episodes,
    required this.compact,
  });

  final List<DownloadItem> episodes;
  final bool compact;

  static final _episodeNumber = RegExp(
    r'S(\d+)\s*E(\d+)',
    caseSensitive: false,
  );
  static (int, int) _order(DownloadItem item) {
    final match = _episodeNumber.firstMatch(item.subtitle);
    if (match == null) return (0, 0);
    return (int.tryParse(match[1]!) ?? 0, int.tryParse(match[2]!) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final first = episodes.first;
    final sorted = [...episodes]
      ..sort((a, b) {
        final (seasonA, episodeA) = _order(a);
        final (seasonB, episodeB) = _order(b);
        final seasonOrder = seasonA.compareTo(seasonB);
        return seasonOrder != 0 ? seasonOrder : episodeA.compareTo(episodeB);
      });
    final bytes = episodes.fold<int>(
      0,
      (sum, item) => sum + (item.totalBytes ?? 0),
    );
    return _DownloadSurface(
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.all(12),
        shape: const Border(),
        collapsedShape: const Border(),
        leading: _DownloadArt(item: first, compact: compact, series: true),
        title: Text(
          first.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          [
            episodes.length == 1 ? '1 episode' : '${episodes.length} episodes',
            if (bytes > 0) downloadSize(bytes),
          ].join(' · '),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        children: [
          for (final episode in sorted)
            DecoratedBox(
              key: ValueKey(episode.itemId),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(top: BorderSide(color: AppColors.surfaceLight)),
              ),
              child: _DownloadRow(item: episode, compact: compact),
            ),
        ],
      ),
    );
  }
}

class _DownloadArt extends StatelessWidget {
  const _DownloadArt({
    required this.item,
    required this.compact,
    this.series = false,
  });

  final DownloadItem item;
  final bool compact;
  final bool series;

  @override
  Widget build(BuildContext context) {
    final episode = !series && item.kind == WatchKind.episode;
    final size = compact ? 56.0 : 72.0;
    return MediaArtwork(
      url: episode ? item.episodeImageUrl ?? item.imageUrl : item.imageUrl,
      title: episode && item.subtitle.isNotEmpty ? item.subtitle : item.title,
      kind: series
          ? ArtworkKind.series
          : episode
          ? ArtworkKind.episode
          : ArtworkKind.movie,
      width: episode && !compact ? 104 : size,
      height: episode ? size : size + 8,
      cacheWidth: 224,
      icon: Icons.download_done_rounded,
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({super.key, required this.item, required this.compact});

  final DownloadItem item;
  final bool compact;

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final urls = ref.read(playbackUrlsProvider);
    final manager = ref.read(downloadManagerProvider.notifier);
    await runDownloadAction(context, () async {
      final movie = item.kind == WatchKind.movie
          ? await db.getMovie(item.sourceId, item.itemId)
          : null;
      final url = item.kind == WatchKind.episode
          ? urls?.episode(item.itemId, item.containerExtension)
          : movie == null
          ? null
          : urls?.movie(movie, containerExtension: item.containerExtension);
      if (!context.mounted) return;
      if (url == null || url.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This title is unavailable in your playlist.'),
          ),
        );
        return;
      }
      await manager.start(
        sourceId: item.sourceId,
        kind: item.kind,
        itemId: item.itemId,
        url: url,
        title: item.title,
        seriesId: item.seriesId,
        subtitle: item.subtitle,
        imageUrl: item.imageUrl,
        episodeImageUrl: item.episodeImageUrl,
        containerExtension: item.containerExtension,
      );
    }, errorMessage: 'Could not start the download. Try again.');
  }

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final resume = ref.read(resumeServiceProvider);
    final messenger = ScaffoldMessenger.of(context);
    await runDownloadAction(context, () async {
      if (!File(item.filePath).existsSync()) {
        messenger.showSnackBar(
          SnackBar(
            content: const Text('The downloaded file is missing.'),
            action: SnackBarAction(
              label: 'Download again',
              onPressed: () {
                if (context.mounted) _retry(context, ref);
              },
            ),
          ),
        );
        return;
      }
      final position = await db
          .watchPosition(item.sourceId, item.kind, item.itemId)
          .first;
      if (!context.mounted) return;
      await startPlayback(
        context,
        ref,
        PlayerArgs.single(
          url: item.filePath,
          title: item.title,
          subtitle: item.subtitle,
          startAt: position == null
              ? null
              : Duration(seconds: position.positionSecs),
          identity: switch (item.kind) {
            WatchKind.movie => PlaybackIdentity(
              itemType: 'MOVIE',
              itemId: '${item.itemId}',
            ),
            WatchKind.episode when item.seriesId != null => PlaybackIdentity(
              itemType: 'SERIES',
              itemId: '${item.seriesId}',
              episodeId: '${item.itemId}',
            ),
            _ => null,
          },
          onProgress: (_, pos, dur) => resume?.report(
            kind: item.kind,
            itemId: item.itemId,
            seriesId: item.seriesId,
            title: item.title,
            subtitle: item.subtitle,
            imageUrl: item.imageUrl,
            containerExtension: item.containerExtension,
            position: pos,
            duration: dur,
          ),
        ),
        localOnly: true,
      );
    }, errorMessage: 'Could not open the downloaded file.');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(
      downloadManagerProvider.select(
        (map) => map[(item.sourceId, item.kind, item.itemId)],
      ),
    );
    final manager = ref.read(downloadManagerProvider.notifier);
    final saved = item.status == DownloadStatus.done;
    final label = switch (progress?.phase) {
      DownloadPhase.queued => 'Queued',
      DownloadPhase.downloading => 'Downloading',
      DownloadPhase.retrying => 'Waiting to retry',
      null when saved =>
        (item.totalBytes ?? 0) > 0
            ? downloadSize(item.totalBytes!)
            : 'Ready offline',
      null when item.status == DownloadStatus.failed => 'Download failed',
      null when item.status == DownloadStatus.noSpace => 'Not enough storage',
      null => 'Download interrupted',
    };
    final title = item.kind == WatchKind.episode && item.subtitle.isNotEmpty
        ? item.subtitle
        : item.title;
    final canRetry = !saved && progress == null;
    final (actionIcon, actionLabel, action) = saved
        ? (Icons.play_arrow_rounded, 'Play offline', () => _play(context, ref))
        : canRetry
        ? (
            Icons.refresh_rounded,
            item.status == DownloadStatus.downloading ? 'Resume' : 'Retry',
            () => _retry(context, ref),
          )
        : (
            Icons.close_rounded,
            'Cancel download',
            () => runDownloadAction(
              context,
              () => manager.cancel(item.sourceId, item.kind, item.itemId),
              errorMessage: 'Could not cancel the download. Try again.',
            ),
          );
    final actions = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (progress != null)
          IconButton.filledTonal(
            tooltip: actionLabel,
            onPressed: action,
            icon: Icon(actionIcon),
          )
        else
          FilledButton.tonalIcon(
            onPressed: action,
            icon: Icon(actionIcon),
            label: Text(actionLabel),
          ),
        if (progress == null)
          IconButton(
            tooltip: 'Remove download',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => confirmDownloadRemoval(context, manager, item),
          ),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final stackActions =
              bounds.maxWidth < 420 ||
              MediaQuery.textScalerOf(context).scale(16) > 23;
          final info = Row(
            children: [
              _DownloadArt(item: item, compact: compact),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        color:
                            item.status == DownloadStatus.failed ||
                                item.status == DownloadStatus.noSpace
                            ? AppColors.error
                            : AppColors.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (progress?.phase == DownloadPhase.downloading)
                      DownloadProgressDetails(progress: progress),
                  ],
                ),
              ),
            ],
          );
          return stackActions
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    info,
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: actions,
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 16),
                    actions,
                  ],
                );
        },
      ),
    );
  }
}
