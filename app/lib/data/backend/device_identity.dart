import 'dart:io';
import 'dart:math';

import '../../core/responsive/form_factor.dart';
import '../../core/app_platform.dart';
import 'key_value_store.dart';

/// Stable per-install address for remote playback and device presence.
class DeviceIdentity {
  const DeviceIdentity({required this.deviceId, required this.platform});

  final String deviceId;
  final String platform;
}

const String _kDeviceId = 'device.id';

/// Returns the persisted device id, generating and storing one on first launch.
Future<DeviceIdentity> loadOrCreateDeviceIdentity(KeyValueStore store) async {
  var id = await store.read(_kDeviceId);
  if (id == null || id.length < 8) {
    id = _generateDeviceId();
    await store.write(_kDeviceId, id);
  }
  return DeviceIdentity(deviceId: id, platform: currentPlatform());
}

String currentPlatform() {
  if (isTizenPlatform) return 'tizen';
  if (isWebOsPlatform) return 'webos';
  if (kTvBuild) return 'androidtv';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  if (Platform.isMacOS) return 'macos';
  if (Platform.isWindows) return 'windows';
  if (Platform.isLinux) return 'linux';
  return 'unknown';
}

String _generateDeviceId() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
