import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_image.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/providers.dart';
import 'download_progress_details.dart';
import '../player/player_screen.dart';
import '../remote/cast_session.dart';

/// Videos saved on this device. Rows show live progress while downloading;
/// finished ones play offline (with resume) and can be removed.
class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    DownloadItem item,
  ) async {
    if (!File(item.filePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The downloaded file is missing.')),
      );
      return;
    }
    final db = ref.read(databaseProvider);
    final resume = ref.read(resumeServiceProvider);
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
    );
  }

  static Widget _poster(String? imageUrl, {double width = 48}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        width: width,
        height: width * 4 / 3,
        child: imageUrl == null
            ? const ColoredBox(
                color: AppColors.surfaceLight,
                child: Icon(
                  Icons.movie_rounded,
                  color: AppColors.textSecondary,
                ),
              )
            : AppImage(url: imageUrl, memCacheWidth: 96),
      ),
    );
  }

  /// One download row. [primary] overrides the title (episode label inside a
  /// series group); [dense]/[showPoster] tighten the grouped episode rows.
  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    DownloadItem item, {
    required DownloadProgress? progress,
    String? primary,
    bool showPoster = true,
    bool dense = false,
  }) {
    final manager = ref.read(downloadManagerProvider.notifier);
    final downloading = item.status == DownloadStatus.downloading;
    final queued = progress?.phase == DownloadPhase.queued;
    final meta = [
      if (primary == null && item.subtitle.isNotEmpty) item.subtitle,
      if ((item.totalBytes ?? 0) > 0) downloadSize(item.totalBytes!),
    ].where((s) => s.isNotEmpty).join('  ·  ');

    return ListTile(
      dense: dense,
      contentPadding: dense ? const EdgeInsets.only(left: 20, right: 4) : null,
      onTap: downloading ? null : () => _play(context, ref, item),
      leading: showPoster
          ? _poster(item.episodeImageUrl ?? item.imageUrl)
          : null,
      title: Text(
        primary ?? item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: downloading
          ? (queued
                ? const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      'Queued',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  )
                : DownloadProgressDetails(progress: progress))
          : Text(
              meta,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
      trailing: downloading
          ? IconButton(
              tooltip: queued ? 'Cancel queued download' : 'Cancel',
              onPressed: () => manager.cancel(item.kind, item.itemId),
              icon: const Icon(Icons.close_rounded),
            )
          : IconButton(
              tooltip: 'Remove download',
              onPressed: () => manager.remove(item),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.textSecondary,
              ),
            ),
    );
  }

  static int _episodeOrder(DownloadItem e) {
    final match = RegExp(r'S(\d+)\s*E(\d+)').firstMatch(e.subtitle);
    if (match == null) return 0;
    return int.parse(match.group(1)!) * 1000 + int.parse(match.group(2)!);
  }

  Widget _seriesGroup(
    BuildContext context,
    WidgetRef ref,
    List<DownloadItem> episodes,
    Map<(WatchKind, int), DownloadProgress> progressMap,
  ) {
    final sorted = [...episodes]
      ..sort((a, b) => _episodeOrder(a).compareTo(_episodeOrder(b)));
    final first = sorted.first;
    final active = sorted
        .where((e) => e.status == DownloadStatus.downloading)
        .length;
    final totalBytes = sorted.fold<int>(
      0,
      (sum, e) => sum + (e.totalBytes ?? 0),
    );
    final count = sorted.length;
    final subtitle = [
      '$count ${count == 1 ? 'episode' : 'episodes'}',
      if (active > 0)
        '$active downloading'
      else if (totalBytes > 0)
        downloadSize(totalBytes),
    ].join('  ·  ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.only(bottom: 4),
          leading: _poster(first.imageUrl),
          title: Text(
            first.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          children: [
            for (final e in sorted)
              _tile(
                context,
                ref,
                e,
                progress: progressMap[(e.kind, e.itemId)],
                primary: e.subtitle.isEmpty ? e.title : e.subtitle,
                dense: true,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(activeSourceProvider).value;
    final progressMap = ref.watch(downloadManagerProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      body: source == null
          ? const Center(child: Text('No playlist configured.'))
          : StreamBuilder(
              stream: db.watchDownloads(source.id),
              builder: (context, snapshot) {
                final items = snapshot.data ?? const <DownloadItem>[];
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'Nothing downloaded yet.\nUse the download button on a '
                      'movie to watch it offline.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                // Episodes collapse under one expandable tile per series;
                // movies stay as standalone rows. Each series takes the
                // position of its most recent episode in the list.
                final seriesEpisodes = <int, List<DownloadItem>>{};
                for (final item in items) {
                  final sid = item.seriesId;
                  if (item.kind == WatchKind.episode && sid != null) {
                    (seriesEpisodes[sid] ??= []).add(item);
                  }
                }
                final rendered = <int>{};
                final entries = <Widget>[];
                for (final item in items) {
                  final sid = item.seriesId;
                  if (item.kind == WatchKind.episode && sid != null) {
                    if (rendered.add(sid)) {
                      entries.add(
                        _seriesGroup(
                          context,
                          ref,
                          seriesEpisodes[sid]!,
                          progressMap,
                        ),
                      );
                    }
                  } else {
                    entries.add(
                      _tile(
                        context,
                        ref,
                        item,
                        progress: progressMap[(item.kind, item.itemId)],
                      ),
                    );
                  }
                }
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  children: entries,
                );
              },
            ),
    );
  }
}
