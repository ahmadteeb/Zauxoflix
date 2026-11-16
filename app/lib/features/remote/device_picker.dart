import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
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
  return showModalBottomSheet<RemoteDevice>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: FutureBuilder(
        future: devices,
        builder: (context, snapshot) {
          final Widget body;
          if (snapshot.hasError) {
            body = _Notice(
              snapshot.error is RemoteException
                  ? (snapshot.error! as RemoteException).message
                  : 'Could not load your devices.',
            );
          } else if (!snapshot.hasData) {
            body = const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            );
          } else {
            final online = [
              for (final device in snapshot.data!)
                if (device.online &&
                    device.isTv &&
                    device.deviceId != selfDeviceId)
                  device,
            ];
            body = online.isEmpty
                ? const _Notice(
                    'No TVs are online. Open Zauxoflix on your TV '
                    'and sign in to this account.',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final device in online)
                        ListTile(
                          leading: const Icon(
                            Icons.tv_rounded,
                            color: AppColors.textPrimary,
                          ),
                          title: Text(device.displayName),
                          trailing: const Icon(
                            Icons.play_arrow_rounded,
                            color: AppColors.textSecondary,
                          ),
                          onTap: () => Navigator.of(context).pop(device),
                        ),
                    ],
                  );
          }
          return ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              body,
            ],
          );
        },
      ),
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
