import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:zauxoflix/core/app_platform.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/data/backend/device_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('webOS is detected without treating desktop Linux as a TV', () {
    expect(
      detectWebOsRuntime(operatingSystem: 'linux', hasLunaApi: () => true),
      isTrue,
    );
    expect(
      detectWebOsRuntime(operatingSystem: 'linux', hasLunaApi: () => false),
      isFalse,
    );
    expect(
      detectWebOsRuntime(
        operatingSystem: 'linux',
        hasLunaApi: () => throw ArgumentError('Missing library'),
      ),
      isFalse,
    );
    expect(
      detectWebOsRuntime(
        operatingSystem: 'webos',
        hasLunaApi: () => throw StateError('Unexpected probe'),
      ),
      isTrue,
    );
    for (final os in ['android', 'ios', 'macos', 'windows', 'tizen']) {
      expect(
        detectWebOsRuntime(
          operatingSystem: os,
          hasLunaApi: () => throw StateError('Unexpected probe'),
        ),
        isFalse,
      );
    }
  });

  test('Android TV mode follows the native capability response', () async {
    const channel = MethodChannel('zauxoflix/device');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    for (final result in [true, false, null]) {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'isTv');
        return result;
      });
      expect(await readAndroidTvMode(), result ?? false);
    }
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'unavailable'),
    );
    expect(await readAndroidTvMode(), isFalse);
    messenger.setMockMethodCallHandler(channel, null);
    expect(await readAndroidTvMode(), isFalse);
  });
  test(
    'Linux-reported Tizen is detected through its native application API',
    () {
      expect(
        detectTizenRuntime(operatingSystem: 'linux', hasAppApi: () => true),
        isTrue,
      );
    },
  );

  test(
    'desktop Linux stays desktop when the Tizen library or symbol is absent',
    () {
      expect(
        detectTizenRuntime(operatingSystem: 'linux', hasAppApi: () => false),
        isFalse,
      );
      expect(
        detectTizenRuntime(
          operatingSystem: 'linux',
          hasAppApi: () => throw ArgumentError('Library not found'),
        ),
        isFalse,
      );
    },
  );

  test('other operating systems do not load a Tizen library', () {
    for (final os in ['android', 'ios', 'macos', 'windows', 'tizen']) {
      expect(
        detectTizenRuntime(
          operatingSystem: os,
          hasAppApi: () => throw StateError('Unexpected native probe'),
        ),
        os == 'tizen',
      );
    }
  });

  test('runtime identity selects compatible plugins and TV mode', () {
    expect(
      isFvpPlatform,
      isDesktopPlatform || Platform.isIOS || Platform.isAndroid,
    );
    if (isTizenPlatform) {
      expect(isDesktopPlatform, isFalse);
      expect(isFvpPlatform, isFalse);
      expect(kTvBuild, isTrue);
      expect(currentPlatform(), 'tizen');
    } else if (isWebOsPlatform) {
      expect(isDesktopPlatform, isFalse);
      expect(isFvpPlatform, isFalse);
      expect(kTvBuild, isTrue);
      expect(currentPlatform(), 'webos');
    } else {
      expect(
        isDesktopPlatform,
        Platform.isLinux || Platform.isWindows || Platform.isMacOS,
      );
    }
  });
}
