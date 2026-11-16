import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum FormFactor { mobile, tablet, desktop, tv }

/// True on TV devices. Seeded from --dart-define=TV_MODE=true (still honored
/// for desktop testing) and upgraded at startup by [detectTvDevice], which
/// asks Android whether the device is a leanback/television build.
bool kTvBuild = const bool.fromEnvironment('TV_MODE');

/// Runs once in main() before the first frame so [kTvBuild] is settled before
/// any layout or focus decision reads it. Best-effort: a missing channel
/// (e.g. tests) just keeps the compile-time value.
Future<void> detectTvDevice() async {
  if (kTvBuild || kIsWeb || !Platform.isAndroid) return;
  try {
    const channel = MethodChannel('zauxoflix/device');
    kTvBuild = await channel.invokeMethod<bool>('isTv') ?? false;
  } on Object {
    // Keep the compile-time default.
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
