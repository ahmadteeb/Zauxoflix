import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/providers.dart';

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

  Future<void> _confirmRemove(
    BuildContext context,
    DownloadManager manager,
    DownloadItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove download?'),
        content: Text('"${item.title}" will be deleted from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) await manager.remove(item);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final progress = ref.watch(downloadManagerProvider)[(kind, itemId)];
    final manager = ref.read(downloadManagerProvider.notifier);

    return StreamBuilder(
      stream: db.watchDownload(sourceId, kind, itemId),
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (progress != null) {
          final queued = progress.phase == DownloadPhase.queued;
          final indicator = _DownloadRing(
            // Queued and the initial pre-byte moment both show a spinner.
            value: queued || progress.value <= 0 ? null : progress.value,
          );
          final tooltip = queued ? 'Queued — tap to cancel' : 'Cancel download';
          if (compact) {
            return IconButton(
              tooltip: tooltip,
              onPressed: () => manager.cancel(kind, itemId),
              icon: indicator,
            );
          }
          return Tooltip(
            message: tooltip,
            child: OutlinedButton.icon(
              onPressed: () => manager.cancel(kind, itemId),
              style: _style,
              icon: indicator,
              label: Text(
                queued ? 'Queued' : '${(progress.value * 100).round()}%',
              ),
            ),
          );
        }
        if (item != null && item.status == DownloadStatus.done) {
          if (compact) {
            return IconButton(
              tooltip: 'Remove download',
              onPressed: () => _confirmRemove(context, manager, item),
              icon: const Icon(
                Icons.download_done_rounded,
                color: AppColors.primary,
              ),
            );
          }
          return Tooltip(
            message: 'Remove download',
            child: OutlinedButton.icon(
              onPressed: () => _confirmRemove(context, manager, item),
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
        void start() => manager.start(
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
        );
        if (compact) {
          return IconButton(
            tooltip: 'Download for offline playback',
            onPressed: url == null ? null : start,
            icon: const Icon(
              Icons.download_rounded,
              color: AppColors.textSecondary,
            ),
          );
        }
        return Tooltip(
          message: 'Download for offline playback',
          child: OutlinedButton(
            onPressed: url == null ? null : start,
            style: _style,
            child: const Icon(Icons.download_rounded, size: 24),
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
