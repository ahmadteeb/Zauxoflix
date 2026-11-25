import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/backend/remote_models.dart';

void main() {
  test('Cast picker recognizes paired TV platforms', () {
    const platforms = {
      'androidtv': 'Android TV',
      'webos': 'LG webOS TV',
      'tizen': 'Samsung TV',
    };
    for (final entry in platforms.entries) {
      final device = RemoteDevice(
        deviceId: 'tv',
        online: true,
        platform: entry.key,
      );
      expect(device.isTv, isTrue, reason: entry.key);
      expect(device.displayName, entry.value);
    }
    const desktop = RemoteDevice(
      deviceId: 'desktop',
      online: true,
      platform: 'linux',
    );
    expect(desktop.isTv, isFalse);
  });
}
