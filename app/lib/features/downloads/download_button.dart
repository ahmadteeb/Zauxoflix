import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/providers.dart';
import 'download_actions.dart';
import 'download_progress_details.dart';

/// Action cycling through the download lifecycle:
/// not downloaded → downloading (tap cancels) → downloaded (tap removes).
/// [compact] renders icon-only for tight spots like episode rows.
class DownloadButton extends ConsumerWidget {
  const DownloadButton({
    super.key,
    required this.sourceId,
    required this.kind,
    required this.itemId,
    required this.title,
    required this.url,
    this.seriesId,
    this.subtitle = '',
    this.imageUrl,
    this.episodeImageUrl,
    this.containerExtension,
    this.compact = false,
  });

  final int sourceId;
  final WatchKind kind;
  final int itemId;
  final int? seriesId;
  final String title;
  final String? url;
  final String subtitle;
  final String? imageUrl;
  final String? episodeImageUrl;
  final String? containerExtension;
  final bool compact;

  static ButtonStyle get _style => OutlinedButton.styleFrom(
    foregroundColor: Colors.white,
    side: const BorderSide(color: Colors.white54),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final progress = ref.watch(
      downloadManagerProvider.select((map) => map[(sourceId, kind, itemId)]),
    );
    final manager = ref.read(downloadManagerProvider.notifier);

    return StreamBuilder(
      stream: db.watchDownload(sourceId, kind, itemId),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (progress != null) {
          final status = switch (progress.phase) {
            DownloadPhase.queued => 'Queued',
            DownloadPhase.retrying => 'Waiting to retry',
            DownloadPhase.downloading => null,
          };
          final indicator = _DownloadRing(
            value: status != null || progress.totalBytes <= 0
                ? null
                : progress.value,
          );
          final tooltip =
              '${status ?? downloadProgressText(progress)}\nTap to cancel';
          void cancel() => runDownloadAction(
            context,
            () => manager.cancel(sourceId, kind, itemId),
            errorMessage: 'Could not cancel the download. Try again.',
          );
          if (compact) {
            return IconButton(
              tooltip: tooltip,
              onPressed: cancel,
              icon: indicator,
            );
          }
          return Tooltip(
            message: tooltip,
            child: OutlinedButton.icon(
              onPressed: cancel,
              style: _style,
              icon: indicator,
              label: Text(
                status ??
                    (progress.totalBytes > 0
                        ? '${(progress.value * 100).floor()}%'
                        : 'Downloading'),
              ),
            ),
          );
        }
        if (item != null && item.status == DownloadStatus.done) {
          if (compact) {
            return IconButton(
              tooltip: 'Remove download',
              onPressed: () => confirmDownloadRemoval(context, manager, item),
              icon: const Icon(
                Icons.download_done_rounded,
                color: AppColors.primary,
              ),
            );
          }
          return Tooltip(
            message: 'Remove download',
            child: OutlinedButton.icon(
              onPressed: () => confirmDownloadRemoval(context, manager, item),
              style: _style,
              icon: const Icon(
                Icons.download_done_rounded,
                size: 24,
                color: AppColors.primary,
              ),
              label: const Text('Downloaded'),
            ),
          );
        }
        void start() => runDownloadAction(
          context,
          () => manager.start(
            sourceId: sourceId,
            kind: kind,
            itemId: itemId,
            seriesId: seriesId,
            url: url!,
            title: title,
            subtitle: subtitle,
            imageUrl: imageUrl,
            episodeImageUrl: episodeImageUrl,
            containerExtension: containerExtension,
          ),
          errorMessage: 'Could not start the download. Try again.',
        );
        final hint = switch (item?.status) {
          DownloadStatus.failed || DownloadStatus.noSpace => 'Retry download',
          DownloadStatus.downloading => 'Resume download',
          _ => 'Download for offline playback',
        };
        if (compact) {
          return IconButton(
            tooltip: hint,
            onPressed: url == null ? null : start,
            icon: Icon(
              item == null ? Icons.download_rounded : Icons.refresh_rounded,
              color: AppColors.textSecondary,
            ),
          );
        }
        return Tooltip(
          message: hint,
          child: OutlinedButton(
            onPressed: url == null ? null : start,
            style: _style,
            child: Icon(
              item == null ? Icons.download_rounded : Icons.refresh_rounded,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

/// Progress ring with a faint track behind the fill, a rounded leading cap and
/// a small stop square in the middle to signal "tap to cancel". A null [value]
/// spins (queued or waiting on the first bytes).
class _DownloadRing extends StatelessWidget {
  const _DownloadRing({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 2.5,
            strokeCap: StrokeCap.round,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
