import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'seek_frames.dart';

/// One background software decoder reads the media independently of the
/// fullscreen video plane. The source is passed through stdin so provider
/// credentials are never present in process arguments or logs.
class WebOsSeekFrameReader implements SeekFrameReader {
  WebOsSeekFrameReader(this.source);

  final String source;
  Process? _process;
  StreamIterator<List<int>>? _output;
  List<int> _chunk = const [];
  int _offset = 0;
  Timer? _idle;
  bool _disposed = false;
  bool _disabled = false;
  DateTime? _retryAfter;
  int _generation = 0;

  Future<void> _open() async {
    final generation = _generation;
    final sourceUri = Uri.tryParse(source);
    final input = sourceUri?.scheme == 'file'
        ? sourceUri!.toFilePath()
        : source;
    if (input.isEmpty ||
        input.length > 8000 ||
        input.contains('\n') ||
        input.contains('\r')) {
      throw const FormatException('Unsupported video source');
    }
    final process = await Process.start(Platform.resolvedExecutable, const [
      '--seek-frames',
    ]);
    unawaited(process.stderr.drain<void>());
    if (_disposed || generation != _generation) {
      process.kill();
      unawaited(process.stdout.drain<void>());
      unawaited(
        process.stdin.close().then<void>((_) {}).catchError((Object _) {}),
      );
      throw const FormatException('Preview reader closed');
    }
    _process = process;
    // The process can exit on an unsupported stream before stdin has drained.
    unawaited(process.stdin.done.then<void>((_) {}, onError: (Object _) {}));
    _output = StreamIterator(process.stdout);
    process.stdin.writeln(input);
  }

  Future<Uint8List> _take(int length) async {
    final output = _output;
    if (output == null) throw const FormatException('Preview reader closed');
    final bytes = Uint8List(length);
    var copied = 0;
    while (copied < length) {
      if (_offset == _chunk.length) {
        if (!await output.moveNext()) {
          throw const FormatException('Seek frame reader stopped');
        }
        _chunk = output.current;
        _offset = 0;
      }
      final count = (length - copied).clamp(0, _chunk.length - _offset);
      bytes.setRange(copied, copied + count, _chunk, _offset);
      _offset += count;
      copied += count;
    }
    return bytes;
  }

  Future<List<DecodedSeekFrame?>> _read(
    Duration time,
    void Function(List<DecodedSeekFrame?>)? onFrames,
  ) async {
    if (_process == null) await _open();
    _process!.stdin.writeln(time.inMilliseconds);
    await _process!.stdin.flush();
    final frames = <DecodedSeekFrame?>[];
    for (var index = 0; index < 3; index++) {
      final timestamp = ByteData.sublistView(
        await _take(8),
      ).getInt64(0, Endian.little);
      frames.add(
        timestamp < 0
            ? null
            : DecodedSeekFrame(
                Duration(milliseconds: timestamp),
                seekFrameBitmap(await _take(seekFrameByteCount)),
              ),
      );
      if (index == 1 && frames[1] != null) onFrames?.call([...frames, null]);
    }
    return frames;
  }

  @override
  Future<List<DecodedSeekFrame?>> read(
    Duration time, {
    void Function(List<DecodedSeekFrame?>)? onFrames,
  }) async {
    if (_disposed ||
        _disabled ||
        (_retryAfter?.isAfter(DateTime.now()) ?? false)) {
      return const [];
    }
    _idle?.cancel();
    try {
      final frames = await _read(
        time,
        onFrames,
      ).timeout(const Duration(seconds: 6));
      if (!_disposed) {
        _idle = Timer(const Duration(seconds: 3), _close);
      }
      return frames;
    } on ProcessException {
      _disabled = true;
      _close();
      return const [];
    } on Object {
      _retryAfter = DateTime.now().add(const Duration(seconds: 3));
      _close();
      return const [];
    }
  }

  void _close() {
    _generation++;
    _idle?.cancel();
    final output = _output;
    if (output != null) unawaited(output.cancel());
    _output = null;
    _chunk = const [];
    _offset = 0;
    _process?.kill();
    _process = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _close();
  }
}
