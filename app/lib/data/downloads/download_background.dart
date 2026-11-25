part of 'download_manager.dart';

/// The mobile OS owns the actual transfer. Match its task ID to the existing
/// database row so progress and completion survive app suspension/relaunch.
class _BackgroundTransfers {
  _BackgroundTransfers(this._manager) {
    _ready = Future<bool>.microtask(_restore);
  }

  static const _group = 'zauxoflix-downloads';
  final DownloadManager _manager;
  final _canceling = <DownloadKey>{};
  final _startedAt = <DownloadKey, DateTime>{};
  final _downloader = bg.FileDownloader();
  late final Future<bool> _ready;
  StreamSubscription<void>? _updates;

  void dispose() => unawaited(_updates?.cancel());

  Future<void> ensureReady() async {
    if (!await _ready) {
      throw const FormatException('Background downloads are unavailable');
    }
  }

  static String _taskId(DownloadKey key) =>
      'zauxoflix.${key.$1}.${key.$2.name}.${key.$3}';

  static DownloadKey? _taskKey(bg.Task task) {
    if (task.group != _group) return null;
    final parts = task.taskId.split('.');
    if (parts.length != 4 || parts.first != 'zauxoflix') return null;
    final source = int.tryParse(parts[1]);
    final item = int.tryParse(parts[3]);
    final kind = WatchKind.values
        .where((value) => value.name == parts[2])
        .firstOrNull;
    return source == null || item == null || kind == null
        ? null
        : (source, kind, item);
  }

  Future<bool> _restore() async {
    if (!_manager._mounted) return false;
    try {
      await _downloader.configure(
        globalConfig: [
          (bg.Config.checkAvailableSpace, DownloadStorage.minimumFreeMiB),
          (bg.Config.holdingQueue, (1, null, null)),
        ],
        androidConfig: [
          (bg.Config.useCacheDir, bg.Config.never),
          (bg.Config.runInForeground, true),
        ],
        iOSConfig: (bg.Config.resourceTimeout, const Duration(hours: 12)),
      );
      if (Platform.isAndroid) {
        _downloader.configureNotificationForGroup(
          _group,
          running: const bg.TaskNotification(
            'Zauxoflix download',
            '{displayName}',
          ),
          progressBar: true,
        );
      }
      if (!_manager._mounted) return false;
      final wifi = await _manager._wifiOnly();
      final policy = wifi
          ? bg.RequireWiFi.forAllTasks
          : bg.RequireWiFi.forNoTasks;
      if (await _downloader.getRequireWiFiSetting() != policy) {
        await DownloadWifiPreference.applyToTransfers(wifi);
      }
      if (!_manager._mounted) return false;
      _updates = _downloader.updates
          .asyncMap(_update)
          .listen(null, onError: (Object _, StackTrace _) {});
      await _downloader.trackTasksInGroup(
        _group,
        markDownloadedComplete: false,
      );
      await _downloader.resumeFromBackground();
      final records = await _downloader.database.allRecords(group: _group);
      for (final record in records) {
        await _update(
          bg.TaskStatusUpdate(record.task, record.status, record.exception),
        );
        if (record.status == bg.TaskStatus.running && record.progress > 0) {
          await _update(
            bg.TaskProgressUpdate(
              record.task,
              record.progress,
              record.expectedFileSize,
            ),
          );
        }
      }
      if (!_manager._mounted) return false;
      final (_, rejected) = await _downloader.rescheduleKilledTasks();
      for (final task in rejected) {
        await _update(bg.TaskStatusUpdate(task, bg.TaskStatus.failed));
      }
      return true;
    } on Exception {
      dispose();
      return false;
    }
  }

  Future<void> enqueue(
    DownloadKey key,
    String path,
    String url,
    String title,
  ) async {
    final (source, kind, item) = key;
    final db = _manager._db;
    final task = bg.DownloadTask(
      taskId: _taskId(key),
      url: url,
      filename: File(path).uri.pathSegments.last,
      displayName: title,
      directory: 'Zauxoflix/Downloads',
      group: _group,
      updates: bg.Updates.statusAndProgress,
      allowPause: true,
      retries: 3,
    );
    _manager._publish(key, const DownloadProgress(DownloadPhase.queued));
    try {
      if (await _downloader.enqueue(task)) return;
      throw const FormatException('Could not queue background download');
    } on Exception {
      await db.markDownloadFailed(source, kind, item);
      _manager._publish(key, null);
      rethrow;
    }
  }

  Future<void> _update(bg.TaskUpdate update) async {
    final key = _taskKey(update.task);
    if (key == null || !_manager._mounted || _canceling.contains(key)) return;
    if (update is bg.TaskProgressUpdate) {
      if (update.progress < 0 ||
          update.progress >= 1 ||
          _manager._progress(key) == null) {
        return;
      }
      final total = math.max(0, update.expectedFileSize);
      final now = DateTime.now();
      final started = _startedAt.putIfAbsent(key, () => now);
      _manager._publish(
        key,
        DownloadProgress(
          DownloadPhase.downloading,
          receivedBytes: (update.progress * total).round(),
          totalBytes: total,
          elapsed: now.difference(started),
          bytesPerSecond: math.max(0, update.networkSpeed) * 1024 * 1024,
          fraction: update.progress,
        ),
      );
      return;
    }
    if (update is! bg.TaskStatusUpdate) return;
    final phase = switch (update.status) {
      bg.TaskStatus.enqueued => DownloadPhase.queued,
      bg.TaskStatus.running => DownloadPhase.downloading,
      bg.TaskStatus.waitingToRetry ||
      bg.TaskStatus.paused => DownloadPhase.retrying,
      _ => null,
    };
    final (source, kind, id) = key;
    final db = _manager._db;
    final item = await db.getDownload(source, kind, id);
    if (!_manager._mounted || _canceling.contains(key)) return;
    if (item == null) {
      if (phase != null) await _downloader.cancelTaskWithId(update.task.taskId);
      if (update.status == bg.TaskStatus.complete) {
        await _manager._deleteIfPresent(await update.task.filePath());
      }
    } else if (item.status == DownloadStatus.downloading) {
      if (phase != null) {
        final previous = _manager._progress(key);
        _manager._publish(
          key,
          DownloadProgress(
            phase,
            receivedBytes: previous?.receivedBytes ?? 0,
            totalBytes: previous?.totalBytes ?? 0,
            elapsed: previous?.elapsed ?? Duration.zero,
            fraction: previous?.fraction,
          ),
        );
        return;
      }
      final path = await update.task.filePath();
      final file = File(path);
      if (update.status == bg.TaskStatus.complete &&
          file.existsSync() &&
          file.lengthSync() > 0) {
        await db.markDownloadDone(
          source,
          kind,
          id,
          totalBytes: file.lengthSync(),
          filePath: path,
        );
        try {
          await _manager._deleteIfPresent('${item.filePath}.part');
        } on FileSystemException {
          // A legacy partial file does not invalidate the new file.
        }
      } else {
        final message = update.exception?.description.toLowerCase() ?? '';
        await db.markDownloadFailed(
          source,
          kind,
          id,
          noSpace: message.contains('space') || message.contains('enospc'),
        );
      }
    }
    _startedAt.remove(key);
    _manager._publish(key, null);
    // Terminal records no longer need to retain the private playlist URL.
    await _downloader.database.deleteRecordWithId(update.task.taskId);
  }

  Future<void> cancel(DownloadKey key) async {
    await ensureReady();
    if (!_manager._mounted || !_canceling.add(key)) return;
    final (source, kind, id) = key;
    final db = _manager._db;
    try {
      final item = await db.getDownload(source, kind, id);
      if (item == null || item.status == DownloadStatus.done) return;
      final taskId = _taskId(key);
      if (!await _downloader.cancelTaskWithId(taskId) &&
          await _downloader.taskForId(taskId) != null) {
        throw const FormatException('Could not cancel background download');
      }
      await _manager._removeFiles(item.filePath);
      await db.deleteDownload(source, kind, id);
      await _downloader.database.deleteRecordWithId(taskId);
      _startedAt.remove(key);
      _manager._publish(key, null);
    } finally {
      _canceling.remove(key);
    }
  }

  Future<void> cancelSource(int source) async {
    try {
      await ensureReady();
      final tasks = await _downloader.allTasks(group: _group);
      final ids = [
        for (final task in tasks)
          if (_taskKey(task)?.$1 == source) task.taskId,
      ];
      if (ids.isNotEmpty) await _downloader.cancelTasksWithIds(ids);
    } on Exception {
      // Invalid source records are also removed when reconciling at launch.
    }
  }
}
