import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final downloadStorageProvider = Provider((ref) => const DownloadStorage());

class InsufficientDownloadSpace implements Exception {
  const InsufficientDownloadSpace(this.availableBytes, this.requiredBytes);

  final int availableBytes;
  final int requiredBytes;
}

class DownloadStorage {
  const DownloadStorage();

  static const minimumFreeMiB = 128;
  static const _reserve = minimumFreeMiB * 1024 * 1024;
  static const _channel = MethodChannel('zauxoflix/download_storage');

  Future<void> verify(String directory, {int remainingBytes = 0}) async {
    final available = await freeBytes(directory);
    final needed = remainingBytes + _reserve;
    if (available != null && available < needed) {
      throw InsufficientDownloadSpace(available, needed);
    }
  }

  Future<int?> freeBytes(String directory) async {
    try {
      if (Platform.isWindows || Platform.isAndroid || Platform.isIOS) {
        return await _channel.invokeMethod<int>('freeBytes', directory);
      }
      final result = await Process.run(
        'df',
        ['-Pk', directory],
        environment: {'LC_ALL': 'C'},
      );
      if (result.exitCode != 0) return null;
      final blocks = RegExp(
        r'\s\d+\s+\d+\s+(\d+)\s+\d+%',
      ).firstMatch((result.stdout as String).split('\n').skip(1).join(' '))?[1];
      return blocks == null ? null : int.parse(blocks) * 1024;
    } on Exception {
      // Runtimes without a disk-space API still surface actual write errors.
      return null;
    }
  }
}
