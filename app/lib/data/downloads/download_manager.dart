import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_paths.dart';
import '../db/app_database.dart';
import '../providers.dart';

/// Live state of in-flight downloads, keyed by (kind, itemId). Only downloads
/// that are queued or transferring have an entry; finished/absent items have
/// their persisted state in the Downloads table.
final downloadManagerProvider =
    NotifierProvider<DownloadManager, Map<(WatchKind, int), DownloadProgress>>(
      DownloadManager.new,
    );

/// Whether a tracked download is waiting its turn or actively transferring.
enum DownloadPhase { queued, downloading }

/// Live transfer measurements; a zero total means the server omitted its size.
class DownloadProgress {
  const DownloadProgress(
    this.phase, {
    this.receivedBytes = 0,
    this.totalBytes = 0,
    this.bytesPerSecond = 0,
    this.elapsed = Duration.zero,
  });

  final DownloadPhase phase;
  final int receivedBytes;
  final int totalBytes;
  final double bytesPerSecond;
  final Duration elapsed;

  double get value =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : 0;

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

class DownloadManager
    extends Notifier<Map<(WatchKind, int), DownloadProgress>> {
  final _cancelTokens = <(WatchKind, int), CancelToken>{};
  final _queue = <_Job>[];
  bool _busy = false;

  @override
  Map<(WatchKind, int), DownloadProgress> build() => const {};

  AppDatabase get _db => ref.read(databaseProvider);

  bool isDownloading(WatchKind kind, int itemId) =>
      state.containsKey((kind, itemId));

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
    final key = (kind, itemId);
    if (state.containsKey(key)) return;

    // Sits alongside zauxoflix.sqlite, both under the app's Zauxoflix folder.
    final dir = await downloadsDirectory();
    final ext = (containerExtension == null || containerExtension.isEmpty)
        ? 'mp4'
        : containerExtension;
    final filePath = '${dir.path}/${kind.name}_$itemId.$ext';

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
        createdAt: DateTime.now(),
      ),
    );

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
  }

  /// Runs queued jobs strictly one at a time so a single transfer saturates
  /// the connection instead of many competing for bandwidth. A job that fails
  /// transiently is re-queued with a backoff so the pass keeps cycling until
  /// every download either completes or is canceled.
  Future<void> _pump() async {
    if (_busy || _queue.isEmpty) return;
    _busy = true;
    while (_queue.isNotEmpty) {
      final job = _queue.removeAt(0);
      final wait = job.readyAt.difference(DateTime.now());
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (await _run(job) == _RunResult.retry) {
        job.attempt++;
        job.readyAt = DateTime.now().add(_backoff(job.attempt));
        _queue.add(job);
      }
    }
    _busy = false;
  }

  /// Capped backoff between retries: quick first reconnects, then settling at
  /// 30s so a long watch session keeps probing without spinning.
  Duration _backoff(int attempt) =>
      Duration(seconds: math.min(30, 3 * attempt));

  Future<_RunResult> _run(_Job job) async {
    final key = (job.kind, job.itemId);
    // Canceled while it was still waiting — its entry is already gone.
    if (!state.containsKey(key)) return _RunResult.done;

    final token = CancelToken();
    _cancelTokens[key] = token;
    state = {...state, key: const DownloadProgress(DownloadPhase.downloading)};
    try {
      final total = await _transfer(job, key, token);
      await File(job.partPath).rename(job.filePath);
      await _db.markDownloadDone(
        job.sourceId,
        job.kind,
        job.itemId,
        totalBytes: total,
      );
      _cancelTokens.remove(key);
      state = {...state}..remove(key);
      return _RunResult.done;
    } catch (e) {
      _cancelTokens.remove(key);
      // User canceled (or its row was already dropped): scrub any partial file.
      if ((e is DioException && CancelToken.isCancel(e)) ||
          !state.containsKey(key)) {
        await _deleteQuietly(job.partPath);
        await _deleteQuietly(job.filePath);
        await _db.deleteDownload(job.sourceId, job.kind, job.itemId);
        state = {...state}..remove(key);
        return _RunResult.done;
      }
      // A dead URL (4xx) will never succeed — give up and clean up.
      if (_isPermanent(e)) {
        await _deleteQuietly(job.partPath);
        await _deleteQuietly(job.filePath);
        await _db.deleteDownload(job.sourceId, job.kind, job.itemId);
        state = {...state}..remove(key);
        return _RunResult.done;
      }
      // Transient (timeout, dropped/blocked connection, 5xx): keep the partial
      // file and try again later, resuming from where it stopped.
      final progress = state[key];
      state = {
        ...state,
        key: DownloadProgress(
          DownloadPhase.queued,
          receivedBytes: progress?.receivedBytes ?? 0,
          totalBytes: progress?.totalBytes ?? 0,
          elapsed: job.elapsed,
        ),
      };
      return _RunResult.retry;
    }
  }

  /// Streams the body into the `.part` file, resuming with a Range request when
  /// bytes already exist. Returns the full file size. A stalled transfer trips
  /// [receiveTimeout] and surfaces as a transient failure the caller retries.
  Future<int> _transfer(
    _Job job,
    (WatchKind, int) key,
    CancelToken token,
  ) async {
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
      final total = _totalBytes(response.headers, existing, resumed);

      final sink = file.openWrite(
        mode: resumed ? FileMode.writeOnlyAppend : FileMode.writeOnly,
      );
      var received = resumed ? existing : 0;
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
          publish();
        }
      } finally {
        clock.stop();
        job.elapsed += clock.elapsed;
        await sink.flush();
        await sink.close();
      }
      if (token.isCancelled) throw token.cancelError!;
      return total > 0 ? total : received;
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
    if (e is DioException && e.type == DioExceptionType.badResponse) {
      final code = e.response?.statusCode ?? 0;
      // 4xx means the request itself is wrong (gone/forbidden) and won't heal;
      // 408/429 are the retryable exceptions. 5xx and network errors retry.
      return code >= 400 && code < 500 && code != 408 && code != 429;
    }
    return false;
  }

  /// Cancels a download whether it is transferring or still queued.
  void cancel(WatchKind kind, int itemId) {
    final key = (kind, itemId);
    final token = _cancelTokens[key];
    if (token != null) {
      token.cancel();
      return;
    }
    // Still waiting: drop it from the queue and clean up its placeholder row.
    final index = _queue.indexWhere(
      (j) => j.kind == kind && j.itemId == itemId,
    );
    if (index == -1) return;
    final job = _queue.removeAt(index);
    state = {...state}..remove(key);
    _deleteQuietly(job.partPath);
    _db.deleteDownload(job.sourceId, job.kind, job.itemId);
  }

  /// Removes a finished download (file + row). In-flight ones go through
  /// [cancel], whose error path already cleans up.
  Future<void> remove(DownloadItem item) async {
    cancel(item.kind, item.itemId);
    await _deleteQuietly(item.filePath);
    await _deleteQuietly('${item.filePath}.part');
    await _db.deleteDownload(item.sourceId, item.kind, item.itemId);
  }

  Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } on FileSystemException {
      // Never created — nothing to clean up.
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
