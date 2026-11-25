import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/downloads/download_storage.dart';
import '../../data/providers.dart';
import 'download_progress_details.dart';

Future<void> runDownloadAction(
  BuildContext context,
  Future<void> Function() action, {
  required String errorMessage,
}) async {
  try {
    await action();
  } on InsufficientDownloadSpace catch (problem) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough storage. ${downloadSize(problem.requiredBytes)} needed, '
            '${downloadSize(problem.availableBytes)} free.',
          ),
        ),
      );
    }
  } on Exception {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
    }
  }
}

Future<void> confirmWatchedDownloadRemoval(
  BuildContext context,
  WidgetRef ref,
  List<DownloadItem> preview,
) async {
  if (preview.isEmpty) return;
  final count = preview.length;
  final bytes = preview.fold<int>(
    0,
    (sum, item) => sum + (item.totalBytes ?? 0),
  );
  final caption =
      'Remove $count watched ${count == 1 ? 'episode' : 'episodes'} from this device?';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Remove watched episodes?'),
      content: Text(
        [
          caption,
          if (bytes > 0) 'This can free up ${downloadSize(bytes)}.',
          'Your watch history stays saved.',
        ].join('\n\n'),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: Text('Remove $count'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final sourceId = preview.first.sourceId;
  if (ref.read(activeSourceProvider).value?.id != sourceId) return;
  final db = ref.read(databaseProvider);
  final manager = ref.read(downloadManagerProvider.notifier);
  final confirmedIds = preview.map((item) => item.itemId).toSet();
  await runDownloadAction(context, () async {
    final eligible = await db.watchWatchedDownloads(sourceId).first;
    var removed = 0;
    var failed = 0;
    for (final item in eligible) {
      if (!confirmedIds.contains(item.itemId)) continue;
      try {
        await manager.remove(item);
        removed++;
      } on Exception {
        failed++;
      }
    }
    if (!context.mounted) return;
    final label = removed == 1
        ? 'Removed 1 episode.'
        : 'Removed $removed episodes.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(failed == 0 ? label : '$label Could not remove $failed.'),
      ),
    );
  }, errorMessage: 'Could not remove watched episodes. Try again.');
}

Future<void> confirmDownloadRemoval(
  BuildContext context,
  DownloadManager manager,
  DownloadItem item,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      title: const Text('Remove download?'),
      content: Text(
        '“${item.subtitle.isEmpty ? item.title : item.subtitle}” will be '
        'removed from this device.',
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.pop(dialog, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialog, true),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await runDownloadAction(
      context,
      () => manager.remove(item),
      errorMessage: 'Could not remove the download. Try again.',
    );
  }
}
