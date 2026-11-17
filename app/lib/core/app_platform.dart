import 'dart:ffi';
import 'dart:io';

/// Tizen may report Linux; its application API distinguishes it from a desktop.
final bool isTizenPlatform = detectTizenRuntime(
  operatingSystem: Platform.operatingSystem,
  hasAppApi: () => DynamicLibrary.open(
    'libcapi-appfw-app-common.so.0',
  ).providesSymbol('app_get_id'),
);

/// webOS exposes Luna Service APIs even when Dart reports Linux.
final bool isWebOsPlatform = detectWebOsRuntime(
  operatingSystem: Platform.operatingSystem,
  hasLunaApi: () {
    if (DynamicLibrary.process().providesSymbol('LSRegister')) return true;
    for (final name in [
      'libluna-service2.so.3',
      'libluna-service2.so.2',
      'libluna-service2.so',
    ]) {
      try {
        if (DynamicLibrary.open(name).providesSymbol('LSRegister')) return true;
      } on ArgumentError {
        // Library names vary across webOS SDK versions.
      }
    }
    return false;
  },
);

bool detectTizenRuntime({
  required String operatingSystem,
  required bool Function() hasAppApi,
}) => _detectNativeRuntime(operatingSystem, 'tizen', hasAppApi);

bool detectWebOsRuntime({
  required String operatingSystem,
  required bool Function() hasLunaApi,
}) => _detectNativeRuntime(operatingSystem, 'webos', hasLunaApi);

bool _detectNativeRuntime(String os, String runtime, bool Function() probe) {
  if (os == runtime) return true;
  if (os != 'linux') return false;
  try {
    return probe();
  } on ArgumentError {
    return false;
  }
}

bool get isDesktopPlatform =>
    !isTizenPlatform &&
    !isWebOsPlatform &&
    (Platform.isLinux || Platform.isWindows || Platform.isMacOS);
