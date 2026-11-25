import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:video_player/video_player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final episodeBufferEnabledProvider = Provider<bool>((_) => false);

/// Only seekable, self-contained episode files use the byte buffer. Manifests
/// keep their original base URL so the native player can resolve segments.
bool bufferableEpisode(Uri uri) =>
    (uri.scheme == 'http' || uri.scheme == 'https') &&
    RegExp(
      r'\.(mp4|m4v|mkv|mov|webm|avi)$',
      caseSensitive: false,
    ).hasMatch(uri.path);

const _prefixBytes = 2 * 1024 * 1024;
const _tailBytes = 6 * 1024 * 1024;

class EpisodeBytes {
  EpisodeBytes(
    this.source,
    this.start,
    this.total,
    this.bytes,
    this.type,
    this.validator,
  );
  final Uri source;
  final int start, total;
  final Uint8List bytes;
  final String? type, validator;
  int get end => start + bytes.length - 1;
}

final _contentRange = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$');
final _byteRange = RegExp(r'^bytes=(\d+)-(\d*)$');

HttpClient _client() => HttpClient()
  ..autoUncompress = false
  ..connectionTimeout = const Duration(seconds: 8);

/// Serves one opaque loopback path to the decoder. The outgoing socket is
/// released as soon as the last bytes are in memory, independently of playout.
class EpisodeBuffer {
  EpisodeBuffer(this.source, {EpisodeBytes? prefix}) : _prefix = prefix;
  final Uri source;
  EpisodeBytes? _prefix, _tail, _prepared;
  HttpServer? _server;
  final _active = <HttpClient>{};
  HttpClient? _warming;
  Uri? _attempted;
  String? _agent;
  bool _closed = false;
  bool _direct = false;
  bool get tailAvailable =>
      !_closed && !_direct && _tail != null && _active.isEmpty;

  Future<Uri> open() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    if (_closed) {
      await server.close(force: true);
      return source;
    }
    _server = server;
    final random = Random.secure();
    final token = List.generate(
      20,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final path = '/$token.${source.path.split('.').last}';
    server.listen((request) async {
      if (_closed ||
          request.uri.path != path ||
          !{'GET', 'HEAD'}.contains(request.method)) {
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
        return;
      }
      await _serve(request);
    }, onError: (Object _) {});
    return Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: path,
    );
  }

  /// Never displace an active stream. A seek outside the retained bytes wins
  /// the slot back immediately. Already received prefix bytes stay usable at handoff.
  Future<void> prepare(Uri next) async {
    if (!tailAvailable || !bufferableEpisode(next) || _attempted == next) {
      return;
    }
    cancelPrepared();
    _attempted = next;
    final client = _warming = _client();
    final deadline = Timer(
      const Duration(seconds: 6),
      () => client.close(force: true),
    );
    try {
      final req = await client.getUrl(next);
      if (_agent != null) req.headers.set('user-agent', _agent!);
      req.headers.set('range', 'bytes=0-${_prefixBytes - 1}');
      req.headers.set('accept-encoding', 'identity');
      final response = await req.close();
      final span = _contentRange.firstMatch(
        response.headers.value('content-range') ?? '',
      );
      if (_warming != client ||
          response.headers.value('content-encoding') != null) {
        return;
      }
      final partial =
          response.statusCode == 206 &&
          span != null &&
          int.parse(span[1]!) == 0;
      final total = partial ? int.parse(span[3]!) : response.contentLength;
      if ((!partial && response.statusCode != 200) || total <= 0) return;
      final capacity = min(_prefixBytes, total);
      final bytes = Uint8List(capacity);
      final type = response.headers.value('content-type'),
          validator = _validator(response);
      var used = 0;
      await for (final chunk in response) {
        if (_warming != client || _closed) return;
        final count = min(chunk.length, capacity - used);
        bytes.setRange(used, used + count, chunk);
        used += count;
        if (used > 0) {
          _prepared = EpisodeBytes(
            next,
            0,
            total,
            Uint8List.sublistView(bytes, 0, used),
            type,
            validator,
          );
        }
        if (used == capacity) break;
      }
    } catch (_) {
      // Optional warmup never participates in the playback retry budget.
    } finally {
      deadline.cancel();
      client.close(force: true);
      if (_warming == client) _warming = null;
    }
  }

  EpisodeBytes? takePrepared(Uri uri) {
    final bytes = _prepared;
    cancelPrepared();
    return bytes?.source == uri ? bytes : null;
  }

  void cancelPrepared() {
    _warming?.close(force: true);
    _warming = null;
    _prepared = null;
  }

  static String? _validator(HttpClientResponse response) {
    final tag = response.headers.value('etag');
    return tag != null && !tag.startsWith('W/')
        ? tag
        : response.headers.value('last-modified');
  }

  Future<void> _serve(HttpRequest request) async {
    final out = request.response;
    final range = request.headers.value('range');
    final span = _byteRange.firstMatch(range ?? '');
    final start = span == null ? 0 : int.tryParse(span[1]!);
    final requestedEnd = span == null ? null : int.tryParse(span[2]!);
    final cached = [?_prefix, ?_tail]
        .where(
          (part) =>
              start != null &&
              (range == null || span != null) &&
              start >= part.start &&
              start <= part.end,
        )
        .firstOrNull;
    final end = cached == null
        ? null
        : min(requestedEnd ?? cached.total - 1, cached.total - 1);
    final head = request.method == 'HEAD';
    HttpClient? client;
    bool sent = false;
    try {
      if (cached != null &&
          start != null &&
          end != null &&
          end >= start &&
          end <= cached.end) {
        _cacheHeaders(out, cached, start, end, range != null);
        sent = true;
        if (!head) {
          out.add(
            Uint8List.sublistView(
              cached.bytes,
              start - cached.start,
              end - cached.start + 1,
            ),
          );
        }
        return;
      }
      cancelPrepared();
      final upstream = client = _client();
      _active.add(upstream);
      unawaited(
        out.done.then<void>(
          (_) {},
          onError: (Object _) => upstream.close(force: true),
        ),
      );
      _agent = request.headers.value('user-agent') ?? _agent;
      final req = await upstream.openUrl(request.method, source);
      if (_agent != null) req.headers.set('user-agent', _agent!);
      req.headers.set('accept-encoding', 'identity');
      final join =
          !head &&
          cached == _prefix &&
          cached != null &&
          end != null &&
          start != null &&
          end > cached.end;
      if (join) {
        req.headers.set('range', 'bytes=${cached.end + 1}-$end');
        if (cached.validator != null) {
          req.headers.set('if-range', cached.validator!);
        }
      } else if (range != null) {
        req.headers.set('range', range);
      }
      final response = await req.close();
      final mime = response.headers.contentType?.mimeType.toLowerCase() ?? '';
      if (mime.contains('mpegurl') || mime == 'application/dash+xml') {
        _direct = true;
        out.statusCode = HttpStatus.temporaryRedirect;
        out.headers.set('location', source.toString());
        return;
      }
      final upstreamRange = _contentRange.firstMatch(
        response.headers.value('content-range') ?? '',
      );
      final from = upstreamRange == null ? 0 : int.parse(upstreamRange[1]!);
      final total = upstreamRange == null
          ? response.contentLength
          : int.parse(upstreamRange[3]!);
      final joined =
          join &&
          response.statusCode == 206 &&
          from == cached.end + 1 &&
          total == cached.total &&
          int.parse(upstreamRange![2]!) == end &&
          (cached.validator == null ||
              _validator(response) == cached.validator);
      if (joined) {
        _cacheHeaders(out, cached, start, end, range != null);
        out.add(Uint8List.sublistView(cached.bytes, start));
      } else {
        if (join && response.statusCode != 200) {
          // Changed representation or an origin with inconsistent range support.
          _prefix = null;
          _direct = true;
          out.statusCode = HttpStatus.temporaryRedirect;
          out.headers.set('location', source.toString());
          return;
        }
        out.statusCode = response.statusCode;
        for (final key in [
          'content-type',
          'content-range',
          'accept-ranges',
          'content-encoding',
          'last-modified',
          'etag',
          'retry-after',
        ]) {
          final value = response.headers.value(key);
          if (value != null) out.headers.set(key, value);
        }
        if (response.contentLength >= 0) {
          out.contentLength = response.contentLength;
        }
      }
      sent = true;
      if (head) return;
      final isTail =
          total > 0 &&
          (response.statusCode == 200 ||
              (response.statusCode == 206 &&
                  upstreamRange != null &&
                  int.parse(upstreamRange[2]!) == total - 1)) &&
          response.headers.value('content-encoding') == null;
      final tailStart = max(from, total - _tailBytes);
      final tail = BytesBuilder();
      var offset = from, pending = 0;
      await for (final chunk in response) {
        if (_closed) break;
        out.add(chunk);
        final after = offset + chunk.length;
        if (isTail && after > tailStart && after <= total) {
          tail.add(
            offset < tailStart ? chunk.sublist(tailStart - offset) : chunk,
          );
        } else {
          pending += chunk.length;
          if (pending >= 128 * 1024) {
            await out.flush();
            pending = 0;
          }
        }
        offset = after;
      }
      if (isTail && offset == total && tail.length == total - tailStart) {
        final old = _tail;
        if (old == null || tailStart <= old.start) {
          _tail = EpisodeBytes(
            source,
            tailStart,
            total,
            tail.takeBytes(),
            response.headers.value('content-type'),
            _validator(response),
          );
        }
      }
    } catch (_) {
      if (!sent && !_closed) {
        _direct = true;
        // Let the native backend handle endpoints the Dart client cannot read.
        out.statusCode = HttpStatus.temporaryRedirect;
        out.headers.set('location', source.toString());
      }
    } finally {
      client?.close(force: true);
      _active.remove(client);
      try {
        await out.close();
      } catch (_) {
        /* A decoder seek closes the old range. */
      }
    }
  }

  static void _cacheHeaders(
    HttpResponse out,
    EpisodeBytes bytes,
    int start,
    int end,
    bool partial,
  ) {
    out.statusCode = partial ? 206 : 200;
    out.contentLength = end - start + 1;
    out.headers.set('accept-ranges', 'bytes');
    if (partial) {
      out.headers.set('content-range', 'bytes $start-$end/${bytes.total}');
    }
    if (bytes.type != null) out.headers.set('content-type', bytes.type!);
  }

  void close() {
    if (_closed) return;
    _closed = true;
    cancelPrepared();
    for (final client in _active) {
      client.close(force: true);
    }
    _prefix = null;
    _tail = null;
    unawaited(_server?.close(force: true));
  }
}

/// The native decoder can synchronously wait for a seek on Flutter's UI
/// isolate. Serve its HTTP requests independently so that wait can complete.
class EpisodeBufferWorker {
  EpisodeBufferWorker(this.source, {Future<EpisodeBytes?>? prefix})
    : _prefix = prefix;
  final Uri source;
  Future<EpisodeBytes?>? _prefix;
  Isolate? _isolate;
  SendPort? _commands;
  bool _closed = false;

  Future<Uri> open() async {
    final ready = ReceivePort();
    try {
      final prefix = await _prefix;
      _prefix = null;
      if (_closed) return source;
      _isolate = await Isolate.spawn(
        _run,
        (source, prefix, ready.sendPort),
        onExit: ready.sendPort,
        debugName: 'episode-buffer',
      );
      if (_closed) {
        _isolate?.kill(priority: Isolate.immediate);
        return source;
      }
      final result = await ready.first.timeout(const Duration(seconds: 4));
      if (!_closed && result is (SendPort, Uri)) {
        _commands = result.$1;
        return result.$2;
      }
    } catch (_) {
      // Loopback setup is optional. Native playback can open the source.
    } finally {
      ready.close();
    }
    _isolate?.kill(priority: Isolate.immediate);
    return source;
  }

  void prepare(Uri next) => _commands?.send((#prepare, next));
  void cancelPrepared() => _commands?.send(#cancel);

  Future<EpisodeBytes?> takePrepared(Uri next) async {
    final commands = _commands;
    if (commands == null) return null;
    final reply = ReceivePort();
    try {
      commands.send((#take, next, reply.sendPort));
      final value = await reply.first.timeout(const Duration(seconds: 1));
      return value as EpisodeBytes?;
    } on TimeoutException {
      return null;
    } finally {
      reply.close();
    }
  }

  Future<void> close() async {
    _closed = true;
    final commands = _commands;
    _commands = null;
    final reply = ReceivePort();
    try {
      if (commands != null) {
        commands.send((#close, reply.sendPort));
        await reply.first.timeout(const Duration(seconds: 1));
      }
    } on TimeoutException {
      // Terminating the worker also releases its sockets.
    } finally {
      _isolate?.kill(priority: Isolate.immediate);
      reply.close();
    }
  }

  static Future<void> _run((Uri, EpisodeBytes?, SendPort) args) async {
    final buffer = EpisodeBuffer(args.$1, prefix: args.$2);
    final commands = ReceivePort();
    try {
      args.$3.send((commands.sendPort, await buffer.open()));
      await for (final command in commands) {
        switch (command) {
          case (#prepare, final Uri next):
            unawaited(buffer.prepare(next));
          case #cancel:
            buffer.cancelPrepared();
          case (#take, final Uri next, final SendPort reply):
            reply.send(buffer.takePrepared(next));
          case (#close, final SendPort reply):
            buffer.close();
            reply.send(null);
            return;
        }
      }
    } on SocketException {
      args.$3.send(null);
    } finally {
      commands.close();
      buffer.close();
    }
  }
}

/// Keep the normal video_player lifecycle and the single-decoder handoff.
class BufferedEpisodeController extends VideoPlayerController {
  BufferedEpisodeController(super.source, {Future<EpisodeBytes?>? prefix})
    : buffer = EpisodeBufferWorker(source, prefix: prefix),
      super.networkUrl();
  final EpisodeBufferWorker buffer;
  String? _decoderUrl;
  bool _disposed = false;
  @override
  String get dataSource => _decoderUrl ?? super.dataSource;
  @override
  Future<void> initialize() async {
    _decoderUrl = (await buffer.open()).toString();
    if (!_disposed) await super.initialize();
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await buffer.close();
    await super.dispose();
  }
}
