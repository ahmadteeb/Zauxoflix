import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_platform.dart';

enum FormFactor { mobile, tablet, desktop, tv }

/// Automatically enabled on Tizen/webOS and detected on Android at startup.
/// --dart-define=TV_MODE=true remains available for desktop TV UI testing.
bool kTvBuild =
    isTizenPlatform || isWebOsPlatform || const bool.fromEnvironment('TV_MODE');

/// Runs once in main() before the first frame so [kTvBuild] is settled before
/// any layout or focus decision reads it. Best-effort: a missing channel
/// (e.g. tests) keeps the initial runtime/build setting.
Future<void> detectTvDevice() async {
  if (kTvBuild || kIsWeb || !Platform.isAndroid) return;
  kTvBuild = await readAndroidTvMode();
}

/// Native device capabilities distinguish TVs from phones and tablets.
Future<bool> readAndroidTvMode() async {
  try {
    const channel = MethodChannel('zauxoflix/device');
    return await channel.invokeMethod<bool>('isTv') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

/// Dev/runtime override (settable from Settings); null = auto-detect.
final formFactorOverrideProvider =
    NotifierProvider<FormFactorOverride, FormFactor?>(FormFactorOverride.new);

class FormFactorOverride extends Notifier<FormFactor?> {
  @override
  FormFactor? build() => null;

  void set(FormFactor? value) => state = value;
}

FormFactor formFactorOf(BuildContext context, WidgetRef ref) {
  final override = ref.watch(formFactorOverrideProvider);
  if (override != null) return override;
  if (kTvBuild) return FormFactor.tv;
  final width = MediaQuery.sizeOf(context).width;
  if (width < 700) return FormFactor.mobile;
  if (width < 1100) return FormFactor.tablet;
  return FormFactor.desktop;
}

extension FormFactorX on FormFactor {
  bool get isTv => this == FormFactor.tv;
  bool get usesDpad => this == FormFactor.tv;

  /// Horizontal screen-edge padding for content.
  double get gutter => switch (this) {
    FormFactor.mobile => 16,
    FormFactor.tablet => 32,
    _ => 56,
  };
}
