import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/remote_models.dart';
import '../../data/backend/remote_repository.dart';
import 'remote_control_screen.dart';

/// Detail-page cast flow: pick a device, start the item there, then open the
/// remote for it.
Future<void> castFromDetails(
  BuildContext context,
  WidgetRef ref, {
  required PlaybackIdentity identity,
  int positionSec = 0,
}) async {
  final device = await showRemoteDevicePicker(context, ref);
  if (device == null || !context.mounted) return;
  try {
    await ref
        .read(remoteRepositoryProvider)
        .play(
          targetDeviceId: device.deviceId,
          identity: identity,
          positionSec: positionSec,
        );
  } on RemoteException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
    return;
  }
  if (context.mounted) {
    unawaited(context.push('/remote', extra: RemoteControlArgs(device)));
  }
}

/// Bottom sheet listing the account's online TVs; resolves to the picked
/// device or null. Phones and desktops are senders, never targets.
Future<RemoteDevice?> showRemoteDevicePicker(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Play on a device',
}) {
  final selfDeviceId = ref.read(deviceIdentityProvider).deviceId;
  final devices = ref.read(remoteRepositoryProvider).devices();
  return showAppSheet<RemoteDevice>(
    context,
    title: title,
    icon: Icons.cast_rounded,
    body: (sheet) => FutureBuilder(
      future: devices,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _Notice(
            snapshot.error is RemoteException
                ? (snapshot.error! as RemoteException).message
                : 'Could not load your devices.',
          );
        }
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final online = [
          for (final device in snapshot.data!)
            if (device.online && device.isTv && device.deviceId != selfDeviceId)
              device,
        ];
        if (online.isEmpty) {
          return const _Notice(
            'No TVs are online. Open Zauxoflix on your TV '
            'and sign in to this account.',
          );
        }
        return Column(
          children: [
            for (final (i, device) in online.indexed)
              AppSheetOption(
                title: device.displayName,
                icon: Icons.tv_rounded,
                trailing: Icons.chevron_right_rounded,
                autofocus: i == 0,
                onPressed: () => Navigator.of(sheet).pop(device),
              ),
          ],
        );
      },
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
