import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:background_downloader/background_downloader.dart' as bg;
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_paths.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'download_preferences.dart';
import 'download_storage.dart';

part 'download_background.dart';

typedef DownloadKey = (int sourceId, WatchKind kind, int itemId);

/// Live state of transfers. Completed and failed entries are kept in the DB.
final downloadManagerProvider =
    NotifierProvider<DownloadManager, Map<DownloadKey, DownloadProgress>>(
      DownloadManager.new,
    );

/// Whether a tracked download is waiting its turn or actively transferring.
enum DownloadPhase { queued, downloading, retrying }

/// Live transfer measurements; a zero total means the server omitted its size.
class DownloadProgress {
  const DownloadProgress(
    this.phase, {
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.bytesPerSecond = 0,
    this.elapsed = Duration.zero,
    this.fraction,
  });

  final DownloadPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final Duration elapsed;
  final double? fraction;

  double get value =>
      fraction ??
      (totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0);

  Duration? get remaining => totalBytes > 0 && bytesPerSecond > 0
      ? Duration(
          seconds: (math.max(0, totalBytes - receivedBytes) / bytesPerSecond)
              .ceil(),
        )
      : null;
}

class _Job {
  _Job({
    required this.sourceId,
    required this.kind,
    required this.itemId,
    required this.url,
    required this.filePath,
  });

  final int sourceId;
  final WatchKind kind;
  final int itemId;
  final String url;
  final String filePath;
  DownloadKey get key => (sourceId, kind, itemId);

  /// Where the transfer accumulates until it finishes, then it's renamed onto
  /// [filePath]. Kept across retries so a resumed download continues instead of
  /// starting over.
  String get partPath => '$filePath.part';

  /// Transient-failure retry bookkeeping. A dropped connection (e.g. the panel
  /// only allows one at a time and the user started watching) must not discard
  /// the download — it waits and resumes.
  Duration elapsed = Duration.zero;
  int attempt = 0;
  DateTime readyAt = DateTime.now();
}

enum _RunResult { done, retry }

class DownloadManager extends Notifier<Map<DownloadKey, DownloadProgress>> {
  final _cancelTokens = <DownloadKey, CancelToken>{};
  final _starting = <DownloadKey>{};
  final _queue = <_Job>[];
  _BackgroundTransfers? _mobile;
  Timer? _retryTimer;
  bool _busy = false;

  @override
  Map<DownloadKey, DownloadProgress> build() {
    if (supportsMobileDownloads) {
      _mobile = _BackgroundTransfers(this);
      ref.listen(activeSourceProvider, (previous, next) {
        final source = previous?.value?.id;
        if (source != null && next is AsyncData && next.value?.id != source) {
          unawaited(_mobile?.cancelSource(source));
        }
      });
    }
    ref.onDispose(() {
      _mobile?.dispose();
      _retryTimer?.cancel();
      for (final token in _cancelTokens.values) {
        token.cancel();
      }
    });
    return const {};
  }

  AppDatabase get _db => ref.read(databaseProvider);

  bool get _mounted => ref.mounted;

  DownloadProgress? _progress(DownloadKey key) => state[key];

  void _publish(DownloadKey key, DownloadProgress? progress) {
    if (!ref.mounted) return;
    state = progress == null
        ? ({...state}..remove(key))
        : {...state, key: progress};
  }

  Future<bool> _wifiOnly() => ref.read(downloadWifiProvider.future);

  Future<void> start({
    required int sourceId,
    required WatchKind kind,
    required int itemId,
    required String url,
    required String title,
    int? seriesId,
    String subtitle = '',
    String? imageUrl,
    String? episodeImageUrl,
    String? containerExtension,
  }) async {
    final key = (sourceId, kind, itemId);
    if (state.containsKey(key) || !_starting.add(key)) return;

    try {
      final mobile = _mobile;
      if (mobile != null) await mobile.ensureReady();
      if (!ref.mounted) return;
      final existing = await _db.getDownload(sourceId, kind, itemId);
      if (existing?.status == DownloadStatus.done &&
          File(existing!.filePath).existsSync()) {
        return;
      }
      // Reuse recorded paths for older downloads and their partial files.
      final ext =
          RegExp(r'^[a-zA-Z0-9]{1,10}$').hasMatch(containerExtension ?? '')
          ? containerExtension
          : 'mp4';
      final filePath =
          existing?.filePath ??
          '${(await downloadsDirectory()).path}/${sourceId}_${kind.name}_$itemId.$ext';
      await ref
          .read(downloadStorageProvider)
          .verify(File(filePath).parent.path);
      await _db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: sourceId,
          kind: kind,
          itemId: itemId,
          seriesId: Value(seriesId),
          title: title,
          subtitle: Value(subtitle),
          imageUrl: Value(imageUrl),
          episodeImageUrl: Value(episodeImageUrl),
          containerExtension: Value(containerExtension),
          filePath: filePath,
          status: DownloadStatus.downloading,
          createdAt: existing?.createdAt ?? DateTime.now(),
          totalBytes: const Value(null),
        ),
      );
      if (!ref.mounted) return;
      if (mobile != null) {
        await mobile.enqueue(
          key,
          filePath,
          url,
          subtitle.isEmpty ? title : subtitle,
        );
        return;
      }
      _queue.add(
        _Job(
          sourceId: sourceId,
          kind: kind,
          itemId: itemId,
          url: url,
          filePath: filePath,
        ),
      );
      state = {...state, key: const DownloadProgress(DownloadPhase.queued)};
      unawaited(_pump());
    } finally {
      _starting.remove(key);
    }
  }

  /// Runs queued jobs strictly one at a time so a single transfer saturates
  /// the connection instead of many competing for bandwidth. A job that fails
  /// transiently is re-queued with a backoff so the pass keeps cycling until
  /// every download either completes or is canceled.
  Future<void> _pump() async {
    if (_busy || _queue.isEmpty) return;
    _retryTimer?.cancel();
    _busy = true;
    try {
      while (_queue.isNotEmpty && ref.mounted) {
        final now = DateTime.now();
        final next = _queue.indexWhere((job) => !job.readyAt.isAfter(now));
        if (next == -1) {
          final earliest = _queue.reduce(
            (a, b) => a.readyAt.isBefore(b.readyAt) ? a : b,
          );
          _retryTimer = Timer(earliest.readyAt.difference(now), _pump);
          return;
        }
        final job = _queue.removeAt(next);
        if (await _run(job) == _RunResult.retry) {
          job.attempt++;
          job.readyAt = DateTime.now().add(Duration(seconds: 3 * job.attempt));
          _queue.add(job);
        }
      }
    } finally {
      _busy = false;
    }
  }

  Future<_RunResult> _run(_Job job) async {
    final key = job.key;
    final token = CancelToken();
    _cancelTokens[key] = token;
    final previous = state[key];
    state = {
      ...state,
      key: DownloadProgress(
        DownloadPhase.downloading,
        receivedBytes: previous?.receivedBytes ?? 0,
        totalBytes: previous?.totalBytes ?? 0,
        elapsed: job.elapsed,
      ),
    };
    try {
      final total = await _transfer(job, key, token);
      if (token.isCancelled) throw token.cancelError!;
      await File(job.partPath).rename(job.filePath);
      if (token.isCancelled) throw token.cancelError!;
      await _db.markDownloadDone(
        job.sourceId,
        job.kind,
        job.itemId,
        totalBytes: total,
      );
      return _RunResult.done;
    } catch (e) {
      if (!ref.mounted) return _RunResult.done;
      if (token.isCancelled ||
          e is InsufficientDownloadSpace ||
          _isPermanent(e) ||
          job.attempt >= 3) {
        try {
          if (token.isCancelled) {
            await _removeFiles(job.filePath);
            await _db.deleteDownload(job.sourceId, job.kind, job.itemId);
          } else {
            if (e is DioException && e.response?.statusCode == 416) {
              await _deleteIfPresent(job.partPath);
            }
            await _db.markDownloadFailed(
              job.sourceId,
              job.kind,
              job.itemId,
              noSpace: e is InsufficientDownloadSpace,
            );
          }
        } on Exception {
          // With no live transfer, the persisted row can still be recovered
          // or removed by the viewer once the filesystem or DB is available.
        }
        return _RunResult.done;
      }
      final progress = state[key];
      state = {
        ...state,
        key: DownloadProgress(
          DownloadPhase.retrying,
          receivedBytes: progress?.receivedBytes ?? 0,
          totalBytes: progress?.totalBytes ?? 0,
          elapsed: job.elapsed,
        ),
      };
      return _RunResult.retry;
    } finally {
      _cancelTokens.remove(key);
      if (ref.mounted && state[key]?.phase != DownloadPhase.retrying) {
        state = {...state}..remove(key);
      }
    }
  }

  /// Streams the body into the `.part` file, resuming with a Range request when
  /// bytes already exist. Returns the full file size. A stalled transfer trips
  /// [receiveTimeout] and surfaces as a transient failure the caller retries.
  Future<int> _transfer(_Job job, DownloadKey key, CancelToken token) async {
    final file = File(job.partPath);
    final existing = file.existsSync() ? file.lengthSync() : 0;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    try {
      final response = await dio.get<ResponseBody>(
        job.url,
        cancelToken: token,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: existing > 0
              ? {HttpHeaders.rangeHeader: 'bytes=$existing-'}
              : null,
          // 206 = resumed; 200 = server ignored the range and restarts.
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      );

      final resumed = existing > 0 && response.statusCode == 206;
      final range = response.headers.value(HttpHeaders.contentRangeHeader);
      if (response.statusCode == 206 &&
          (range == null || !range.startsWith('bytes $existing-'))) {
        throw const HttpException('Invalid download range');
      }
      final total = _totalBytes(response.headers, existing, resumed);
      final storage = ref.read(downloadStorageProvider);
      await storage.verify(
        file.parent.path,
        remainingBytes: math.max(0, total - (resumed ? existing : 0)),
      );

      final sink = file.openWrite(
        mode: resumed ? FileMode.writeOnlyAppend : FileMode.writeOnly,
      );
      // Flush and close surface write errors to the transfer. Also listen to
      // the sink's completion so an early disk error isn't unhandled.
      unawaited(
        sink.done.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
      );
      var received = resumed ? existing : 0;
      var nextSpaceCheck = received + 64 * 1024 * 1024;
      final offset = received;
      final clock = Stopwatch()..start();
      var lastUpdate = -250;
      void publish() {
        final milliseconds = clock.elapsedMilliseconds;
        // Avoid rebuilding the downloads UI for every network chunk.
        if (milliseconds - lastUpdate < 250 && received != total) return;
        lastUpdate = milliseconds;
        state = {
          ...state,
          key: DownloadProgress(
            DownloadPhase.downloading,
            receivedBytes: received,
            totalBytes: total,
            elapsed: job.elapsed + clock.elapsed,
            bytesPerSecond: milliseconds >= 250
                ? (received - offset) * 1000 / milliseconds
                : 0,
          ),
        };
      }

      publish();
      try {
        await for (final chunk in response.data!.stream) {
          if (token.isCancelled) break;
          sink.add(chunk);
          received += chunk.length;
          if (received >= nextSpaceCheck) {
            await sink.flush();
            await storage.verify(
              file.parent.path,
              remainingBytes: math.max(0, total - received),
            );
            nextSpaceCheck = received + 64 * 1024 * 1024;
          }
          publish();
        }
      } finally {
        clock.stop();
        job.elapsed += clock.elapsed;
        await sink.flush();
        await sink.close();
      }
      if (token.isCancelled) throw token.cancelError!;
      if (received == 0 || (total > 0 && received != total)) {
        throw const HttpException('Incomplete download');
      }
      return received;
    } finally {
      dio.close();
    }
  }

  /// Full size of the target file. For a resumed (206) response the total lives
  /// in Content-Range (`bytes start-end/total`); otherwise Content-Length is
  /// the whole file.
  int _totalBytes(Headers headers, int existing, bool resumed) {
    final contentLength =
        int.tryParse(headers.value(HttpHeaders.contentLengthHeader) ?? '') ?? 0;
    if (!resumed) return contentLength;
    final range = headers.value('content-range');
    final slash = range?.lastIndexOf('/') ?? -1;
    final fromRange = slash == -1
        ? null
        : int.tryParse(range!.substring(slash + 1));
    return fromRange ?? (contentLength > 0 ? existing + contentLength : 0);
  }

  bool _isPermanent(Object e) {
    if (e is FileSystemException) return true;
    if (e is DioException && e.type == DioExceptionType.badResponse) {
      final code = e.response?.statusCode ?? 0;
      // 4xx means the request itself is wrong (gone/forbidden) and won't heal;
      // 408/429 are the retryable exceptions. 5xx and network errors retry.
      return code >= 400 && code < 500 && code != 408 && code != 429;
    }
    return false;
  }

  /// Cancels a download whether it is transferring or still queued.
  Future<void> cancel(int sourceId, WatchKind kind, int itemId) async {
    final key = (sourceId, kind, itemId);
    final mobile = _mobile;
    if (mobile != null) return mobile.cancel(key);
    final token = _cancelTokens[key];
    if (token != null) {
      token.cancel();
      return;
    }
    // Still waiting: drop it from the queue and clean up its placeholder row.
    final index = _queue.indexWhere((job) => job.key == key);
    if (index == -1) return;
    final job = _queue.removeAt(index);
    try {
      await _deleteIfPresent(job.partPath);
      await _db.deleteDownload(sourceId, kind, itemId);
    } finally {
      state = {...state}..remove(key);
    }
  }

  /// Removes a finished download (file + row). In-flight ones go through
  /// [cancel], whose error path already cleans up.
  Future<void> remove(DownloadItem item) async {
    if (item.status == DownloadStatus.downloading) await _mobile?.ensureReady();
    final key = (item.sourceId, item.kind, item.itemId);
    if (state.containsKey(key)) {
      await cancel(item.sourceId, item.kind, item.itemId);
      return;
    }
    if (!_starting.add(key)) return;
    try {
      await _removeFiles(item.filePath);
      await _db.deleteDownload(item.sourceId, item.kind, item.itemId);
    } finally {
      _starting.remove(key);
    }
  }

  Future<void> _removeFiles(String path) async {
    await _deleteIfPresent('$path.part');
    await _deleteIfPresent(path);
  }

  Future<void> _deleteIfPresent(String path) async {
    final file = File(path);
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      if (file.existsSync()) rethrow;
    }
  }

  /// The local path to play instead of the network URL, when a completed
  /// download exists on disk.
  Future<String?> localPath(int sourceId, WatchKind kind, int itemId) async {
    final item = await _db.getDownload(sourceId, kind, itemId);
    if (item == null || item.status != DownloadStatus.done) return null;
    return File(item.filePath).existsSync() ? item.filePath : null;
  }
}
