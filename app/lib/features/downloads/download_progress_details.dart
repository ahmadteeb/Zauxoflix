import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/downloads/download_manager.dart';

String downloadSize(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : 1)} ${units[unit]}';
}

String _time(Duration duration) {
  final seconds = duration.inSeconds;
  if (seconds >= 3600) {
    return '${duration.inHours}h ${duration.inMinutes % 60}m';
  }
  if (seconds >= 60) return '${duration.inMinutes}m ${seconds % 60}s';
  return '${seconds}s';
}

String downloadProgressText(DownloadProgress progress) {
  final size = progress.totalBytes > 0
      ? '${(progress.value * 100).floor()}% · '
            '${downloadSize(progress.receivedBytes)} / ${downloadSize(progress.totalBytes)}'
      : '${downloadSize(progress.receivedBytes)} downloaded · Size unknown';
  final details = [
    if (progress.bytesPerSecond > 0)
      '${downloadSize(progress.bytesPerSecond.round())}/s',
    '${_time(progress.elapsed)} elapsed',
    if (progress.remaining case final remaining?) '${_time(remaining)} left',
  ];
  return '$size\n${details.join(' · ')}';
}

class DownloadProgressDetails extends StatelessWidget {
  const DownloadProgressDetails({super.key, required this.progress});

  final DownloadProgress? progress;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress != null && progress!.totalBytes > 0
                ? progress!.value
                : null,
            minHeight: 4,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          progress == null ? 'Connecting…' : downloadProgressText(progress!),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}
