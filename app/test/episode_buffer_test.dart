import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/features/player/episode_buffer.dart';

void main() {
  test(
    'retains the ending, frees its provider slot, and consumes the next prefix exactly once',
    () async {
      final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final first = Uri.parse('http://127.0.0.1:${origin.port}/first.mp4');
      final next = first.resolve('second.mp4');
      final payload = Uint8List.fromList(
        List.generate(2 * 1024 * 1024 + 723, (i) => i % 237),
      );
      final requests = <(String, String?)>[];
      final pendingPrefix = Completer<void>();
      final allowPrefix = Completer<void>();
      var active = 0, peak = 0;
      origin.listen((req) async {
        active++;
        peak = max(peak, active);
        try {
          final range = req.headers.value('range');
          requests.add((req.uri.path, range));
          if (req.uri.path == '/second.mp4' && range == 'bytes=0-2097151') {
            pendingPrefix.complete();
            await allowPrefix.future;
          }
          final match = RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(range ?? '');
          final start = match == null ? 0 : int.parse(match[1]!);
          final end = min(
            payload.length - 1,
            int.tryParse(match?[2] ?? '') ?? payload.length - 1,
          );
          final out = req.response;
          out.statusCode = range == null ? 200 : 206;
          out.headers.set('etag', '"v1"');
          out.headers.set('content-type', 'video/mp4');
          if (range != null) {
            out.headers.set(
              'content-range',
              'bytes $start-$end/${payload.length}',
            );
          }
          out.contentLength = end - start + 1;
          out.add(Uint8List.sublistView(payload, start, end + 1));
          await out.close();
        } finally {
          active--;
        }
      });
      final client = HttpClient();
      final outgoing = EpisodeBuffer(first);
      EpisodeBuffer? incoming;
      Future<Uint8List> read(Uri url, String range) async {
        final req = await client.getUrl(url);
        req.headers.set('range', range);
        final response = await req.close();
        expect(response.statusCode, 206);
        final data = BytesBuilder(copy: false);
        await for (final chunk in response) {
          data.add(chunk);
        }
        return data.takeBytes();
      }

      try {
        final current = await outgoing.open();
        await outgoing.prepare(next);
        expect(requests, isEmpty);
        final offset = payload.length - 500;
        expect(
          await read(current, 'bytes=$offset-'),
          orderedEquals(payload.sublist(offset)),
        );
        expect(outgoing.tailAvailable, isTrue);
        final warm = outgoing.prepare(next);
        await pendingPrefix.future;
        expect(
          await read(current, 'bytes=${offset + 10}-'),
          orderedEquals(payload.sublist(offset + 10)),
        );
        allowPrefix.complete();
        await warm;
        final prefix = outgoing.takePrepared(next);
        expect(prefix?.bytes.length, 2 * 1024 * 1024);
        expect(outgoing.takePrepared(next), isNull);
        outgoing.close();
        incoming = EpisodeBuffer(next, prefix: prefix);
        final uri = await incoming.open();
        expect(
          await read(uri, 'bytes=0-127'),
          orderedEquals(payload.sublist(0, 128)),
        );
        final full = await read(uri, 'bytes=0-');
        expect(full, orderedEquals(payload));
        expect(requests, [
          (first.path, 'bytes=$offset-'),
          (next.path, 'bytes=0-2097151'),
          (next.path, 'bytes=2097152-${payload.length - 1}'),
        ]);
        expect(peak, 1);
      } finally {
        if (!allowPrefix.isCompleted) allowPrefix.complete();
        outgoing.close();
        incoming?.close();
        client.close(force: true);
        await origin.close(force: true);
      }
    },
  );

  test(
    'a synchronous decoder seek can read while the UI isolate is blocked',
    () async {
      final source = Uri.parse('https://example.test/series.mkv');
      final bytes = Uint8List.fromList(utf8.encode('episode'));
      final worker = EpisodeBufferWorker(
        source,
        prefix: Future.value(
          EpisodeBytes(source, 0, bytes.length, bytes, 'video/mp4', null),
        ),
      );
      RawSynchronousSocket? socket;
      try {
        final local = await worker.open();
        expect(local.host, '127.0.0.1');
        socket = RawSynchronousSocket.connectSync(local.host, local.port);
        socket.writeFromSync(
          ascii.encode(
            'GET ${local.path} HTTP/1.1\r\nHost: localhost\r\nRange: bytes=0-6\r\nConnection: close\r\n\r\n',
          ),
        );
        final response = BytesBuilder();
        final deadline = Stopwatch()..start();
        while (deadline.elapsed < const Duration(seconds: 3)) {
          final available = socket.available();
          if (available > 0) {
            final chunk = socket.readSync(available);
            if (chunk != null) response.add(chunk);
            if (latin1.decode(response.toBytes()).endsWith('episode')) break;
          }
          sleep(const Duration(milliseconds: 10));
        }
        expect(latin1.decode(response.toBytes()), endsWith('\r\n\r\nepisode'));
      } finally {
        socket?.closeSync();
        await worker.close();
      }
    },
  );

  test('leaves manifests and non-network inputs with their native player', () {
    expect(
      bufferableEpisode(Uri.parse('https://example.test/a.m3u8')),
      isFalse,
    );
    expect(bufferableEpisode(Uri.parse('file:///a.mp4')), isFalse);
    expect(
      bufferableEpisode(Uri.parse('https://example.test/a.mkv?token=test')),
      isTrue,
    );
  });
}
