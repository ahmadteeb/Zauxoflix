import 'dart:typed_data';

const seekFrameWidth = 192;
const seekFrameHeight = 108;
const seekFrameByteCount = seekFrameWidth * seekFrameHeight * 3;

class DecodedSeekFrame {
  const DecodedSeekFrame(this.time, this.image);

  final Duration time;
  final Uint8List image;
}

abstract interface class SeekFrameReader {
  Future<List<DecodedSeekFrame?>> read(
    Duration time, {
    void Function(List<DecodedSeekFrame?>)? onFrames,
  });
  void dispose();
}

typedef PlaybackSeekFrames =
    Future<void> Function(
      Duration target,
      bool Function() isCurrent,
      void Function(int slot, DecodedSeekFrame frame) onFrame,
    );

// Both native readers emit four-byte-aligned rows of 24-bit BGR. A top-down
// BMP header lets Flutter decode the frame through its normal image pipeline.
Uint8List seekFrameBitmap(Uint8List pixels) {
  final header = ByteData(54)
    ..setUint16(0, 0x4d42, Endian.little)
    ..setUint32(2, 54 + pixels.length, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, seekFrameWidth, Endian.little)
    ..setInt32(22, -seekFrameHeight, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, pixels.length, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pixels))
      .takeBytes();
}
