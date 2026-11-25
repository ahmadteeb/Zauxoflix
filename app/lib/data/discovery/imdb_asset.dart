import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final _assetName = RegExp(
  r'^assets/private_imdb/(imdb-[0-9a-f]{64}\.sqlite)\.gz$',
);

/// A full, user-installed index takes precedence over the optional device copy.
final imdbIndexPathProvider = FutureProvider<String?>((ref) async {
  try {
    final directory = await getApplicationSupportDirectory();
    final full = File('${directory.path}/imdb.sqlite');
    if (full.existsSync()) return full.path;
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets().where(_assetName.hasMatch);
    if (assets.length != 1) return null;
    return await installDeviceImdb(directory, assets.single, rootBundle.load);
  } on MissingPluginException {
    return null;
  } on PlatformException {
    return null;
  } on MissingPlatformDirectoryException {
    return null;
  } on FileSystemException {
    // The rest of the catalog also works when device storage is full.
    return null;
  } on FormatException {
    return null;
  }
});

Future<String> installDeviceImdb(
  Directory directory,
  String asset,
  Future<ByteData> Function(String) load,
) async {
  final filename = _assetName.firstMatch(asset)![1]!;
  final cache = Directory('${directory.path}/imdb-device');
  final file = File('${cache.path}/$filename');
  if (file.existsSync()) return file.path;
  final data = await load(asset);
  final compressed = TransferableTypedData.fromList([
    Uint8List.sublistView(data),
  ]);
  return Isolate.run(() async {
    await cache.create(recursive: true);
    final staging = await cache.createTemp('import-');
    try {
      final bytes = compressed.materialize().asUint8List();
      final pending = File('${staging.path}/index.sqlite');
      const chunkSize = 65536;
      final input = Iterable.generate((bytes.length / chunkSize).ceil(), (i) {
        final start = i * chunkSize;
        return Uint8List.sublistView(
          bytes,
          start,
          (start + chunkSize).clamp(0, bytes.length),
        );
      });
      await Stream<List<int>>.fromIterable(
        input,
      ).transform(gzip.decoder).pipe(pending.openWrite());
      if (!file.existsSync()) await pending.rename(file.path);
      // Only remove completed copies made by older personal builds.
      await for (final old in cache.list()) {
        final oldName = old.uri.pathSegments.last;
        if (old is File &&
            oldName != filename &&
            _assetName.hasMatch('assets/private_imdb/$oldName.gz')) {
          try {
            await old.delete();
          } on FileSystemException {
            // An older app instance may still have this generation open.
          }
        }
      }
      return file.path;
    } finally {
      await staging.delete(recursive: true);
    }
  });
}
