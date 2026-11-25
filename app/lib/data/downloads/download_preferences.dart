import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/responsive/form_factor.dart';

bool get supportsMobileDownloads =>
    !kTvBuild && (Platform.isAndroid || Platform.isIOS);

final downloadWifiProvider =
    AsyncNotifierProvider<DownloadWifiPreference, bool>(
      DownloadWifiPreference.new,
    );

class DownloadWifiPreference extends AsyncNotifier<bool> {
  static const _key = 'downloads.wifi_only';
  final _preferences = SharedPreferencesAsync();

  @override
  Future<bool> build() async => await _preferences.getBool(_key) ?? true;

  static Future<void> applyToTransfers(bool enabled) async {
    final applied = await FileDownloader().requireWiFi(
      enabled ? RequireWiFi.forAllTasks : RequireWiFi.forNoTasks,
    );
    if (!applied) {
      throw const FormatException('Download network policy unavailable');
    }
  }

  Future<void> set(bool enabled) async {
    if (state.isLoading || state.value == enabled) return;
    final previous = state;
    state = const AsyncLoading();
    try {
      await applyToTransfers(enabled);
      try {
        await _preferences.setBool(_key, enabled);
      } on Exception {
        await applyToTransfers(previous.value ?? true);
        rethrow;
      }
      if (ref.mounted) state = AsyncData(enabled);
    } on Exception {
      if (ref.mounted) state = previous;
      rethrow;
    }
  }
}
