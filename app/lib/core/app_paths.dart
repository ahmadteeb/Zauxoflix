import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Root folder for all app data — the database and offline downloads both live
/// under a single `Zauxoflix` folder in the OS documents directory. Created on
/// demand.
Future<Directory> appDataDirectory() async {
  final dir = Directory(
    '${(await getApplicationDocumentsDirectory()).path}/Zauxoflix',
  );
  await dir.create(recursive: true);
  return dir;
}

/// Folder holding offline downloads, nested inside [appDataDirectory].
Future<Directory> downloadsDirectory() async {
  final dir = Directory('${(await appDataDirectory()).path}/Downloads');
  await dir.create(recursive: true);
  return dir;
}
