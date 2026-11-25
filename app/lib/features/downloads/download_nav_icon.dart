import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/providers.dart';

final downloadsForSourceProvider = StreamProvider.autoDispose
    .family<List<DownloadItem>, int>((ref, sourceId) {
      return ref.watch(databaseProvider).watchDownloads(sourceId);
    });

class DownloadNavIcon extends ConsumerWidget {
  const DownloadNavIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final source = ref.watch(
      activeSourceProvider.select((value) => value.value?.id),
    );
    final saved = source == null
        ? 0
        : ref.watch(
            downloadsForSourceProvider(source).select(
              (value) =>
                  value.value
                      ?.where((item) => item.status == DownloadStatus.done)
                      .length ??
                  0,
            ),
          );
    final (active, percent) = ref.watch(
      downloadManagerProvider.select((progress) {
        final jobs = [
          for (final entry in progress.entries)
            if (entry.key.$1 == source) entry.value,
        ];
        final running = jobs
            .where((job) => job.phase == DownloadPhase.downloading)
            .firstOrNull;
        final percent =
            running != null &&
                (running.totalBytes > 0 || running.fraction != null)
            ? (running.value * 100).floor()
            : null;
        return (jobs.length, percent);
      }),
    );
    final savedLabel = saved == 1 ? '1 file saved' : '$saved files saved';
    final progressLabel = switch (percent) {
      final int value => '$value% of current download',
      null when active > 0 => active == 1 ? '1 transfer' : '$active transfers',
      _ => null,
    };
    return Semantics(
      label: 'Downloads',
      value: [savedLabel, ?progressLabel].join(', '),
      child: ExcludeSemantics(
        child: Badge(
          isLabelVisible: saved > 0,
          label: Text(saved > 99 ? '99+' : '$saved'),
          backgroundColor: AppColors.primary,
          textColor: Colors.white,
          offset: const Offset(5, -3),
          child: SizedBox.square(
            dimension: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (active > 0)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      value: percent == null ? null : percent / 100,
                      strokeWidth: 2.5,
                      backgroundColor: AppColors.surfaceLight,
                      color: AppColors.error,
                    ),
                  ),
                const Icon(Icons.download_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
