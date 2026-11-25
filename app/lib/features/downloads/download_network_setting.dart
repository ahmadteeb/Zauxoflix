import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/downloads/download_preferences.dart';
import 'download_actions.dart';

class DownloadNetworkSetting extends ConsumerWidget {
  const DownloadNetworkSetting({super.key, this.contentPadding, this.icon});

  final EdgeInsetsGeometry? contentPadding;
  final IconData? icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wifi = ref.watch(downloadWifiProvider);
    return SwitchListTile(
      contentPadding: contentPadding,
      secondary: icon == null ? null : Icon(icon),
      title: const Text('Wi-Fi only'),
      subtitle: const Text('Downloads can continue in the background'),
      value: wifi.value ?? true,
      onChanged: wifi.isLoading
          ? null
          : (enabled) => runDownloadAction(
              context,
              () => ref.read(downloadWifiProvider.notifier).set(enabled),
              errorMessage: 'Could not change the download network setting.',
            ),
    );
  }
}
