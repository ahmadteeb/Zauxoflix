import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'seek_frames.dart';

/// Reuses the Android playback library's software decoder on a separate
/// isolate. Its reader is exclusively owned by the current player screen.
class AndroidSeekFrameReader implements SeekFrameReader {
  AndroidSeekFrameReader(this.source, this.headers);

  final String source;
  final Map<String, String> headers;
  int _reader = 0;
  Timer? _idle;
  bool _busy = false;
  bool _disposed = false;
  DateTime? _retryAfter;

  @override
  Future<List<DecodedSeekFrame?>> read(
    Duration time, {
    void Function(List<DecodedSeekFrame?>)? onFrames,
  }) async {
    if (_disposed || _busy || (_retryAfter?.isAfter(DateTime.now()) ?? false)) {
      return const [];
    }
    _idle?.cancel();
    _busy = true;
    final updates = ReceivePort()
      ..listen((message) {
        if (!_disposed) onFrames?.call(message as List<DecodedSeekFrame?>);
      });
    try {
      final batch = await _readAndroidInBackground(
        _reader,
        source,
        headers,
        time.inMilliseconds,
        updates.sendPort,
      );
      _reader = batch.reader;
      if (_reader == 0) {
        _retryAfter = DateTime.now().add(const Duration(seconds: 3));
      }
      return _disposed ? const [] : batch.frames;
    } on Object {
      _release();
      _retryAfter = DateTime.now().add(const Duration(seconds: 3));
      return const [];
    } finally {
      updates.close();
      _busy = false;
      if (_disposed) {
        _release();
      } else if (_reader != 0) {
        _idle = Timer(const Duration(seconds: 3), _release);
      }
    }
  }

  void _release() {
    final reader = _reader;
    _reader = 0;
    if (reader != 0) unawaited(_closeAndroidInBackground(reader));
  }

  @override
  void dispose() {
    _disposed = true;
    _idle?.cancel();
    if (!_busy) _release();
  }
}

typedef _FrameBatch = ({int reader, List<DecodedSeekFrame?> frames});

Future<_FrameBatch> _readAndroidInBackground(
  int reader,
  String source,
  Map<String, String> headers,
  int milliseconds,
  SendPort updates,
) => Isolate.run(
  () => _readAndroid(reader, source, headers, milliseconds, updates),
);

Future<void> _closeAndroidInBackground(int reader) =>
    Isolate.run(() => _close(Pointer<Void>.fromAddress(reader)));

final _native = DynamicLibrary.open('libzauxoflix_seek_frames.so');
final _open = _native
    .lookupFunction<
      Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>),
      Pointer<Void> Function(Pointer<Utf8>, Pointer<Utf8>)
    >('zauxoflix_seek_open');
typedef _FrameUpdate = Void Function(Int, Int64, Pointer<Uint8>);

final _read = _native
    .lookupFunction<
      Void Function(
        Pointer<Void>,
        Int64,
        Pointer<NativeFunction<_FrameUpdate>>,
      ),
      void Function(Pointer<Void>, int, Pointer<NativeFunction<_FrameUpdate>>)
    >('zauxoflix_seek_read_incremental');
final _close = _native
    .lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
      'zauxoflix_seek_close',
    );

_FrameBatch _readAndroid(
  int handle,
  String source,
  Map<String, String> headers,
  int milliseconds,
  SendPort updates,
) => using((arena) {
  var reader = Pointer<Void>.fromAddress(handle);
  if (reader == nullptr) {
    final uri = Uri.tryParse(source);
    final path = uri?.scheme == 'file' ? uri!.toFilePath() : source;
    if (path.contains('\u0000')) return (reader: 0, frames: const []);
    final httpHeaders = StringBuffer();
    for (final entry in headers.entries) {
      if (RegExp(r'[:\r\n\x00]').hasMatch(entry.key) ||
          RegExp(r'[\r\n\x00]').hasMatch(entry.value)) {
        continue;
      }
      httpHeaders.write('${entry.key}: ${entry.value}\r\n');
    }
    reader = _open(
      path.toNativeUtf8(allocator: arena),
      httpHeaders.toString().toNativeUtf8(allocator: arena),
    );
    if (reader == nullptr) return (reader: 0, frames: const []);
  }
  try {
    final frames = List<DecodedSeekFrame?>.filled(3, null);
    final update = NativeCallable<_FrameUpdate>.isolateLocal((
      int slot,
      int timestamp,
      Pointer<Uint8> pixels,
    ) {
      final frame = frames[slot] = DecodedSeekFrame(
        Duration(milliseconds: timestamp),
        seekFrameBitmap(
          Uint8List.fromList(pixels.asTypedList(seekFrameByteCount)),
        ),
      );
      updates.send(List<DecodedSeekFrame?>.filled(3, null)..[slot] = frame);
    });
    try {
      _read(reader, milliseconds, update.nativeFunction);
    } finally {
      update.close();
    }
    return (reader: reader.address, frames: frames);
  } on Object {
    // The caller still owns a previously opened reader on error.
    if (handle == 0) _close(reader);
    rethrow;
  }
});
