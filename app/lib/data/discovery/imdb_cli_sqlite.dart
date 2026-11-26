import 'dart:ffi';
import 'dart:io';

import 'package:sqlite3/open.dart';

/// Without Flutter's bundled libraries, point at the SQLite the OS ships.
void useSystemSqlite() {
  if (Platform.isWindows) {
    open.overrideFor(
      OperatingSystem.windows,
      () => DynamicLibrary.open('winsqlite3.dll'),
    );
  } else if (Platform.isLinux) {
    // The unversioned libsqlite3.so only comes with the -dev package.
    open.overrideFor(
      OperatingSystem.linux,
      () => DynamicLibrary.open('libsqlite3.so.0'),
    );
  }
}
