import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/remote_models.dart';
import '../../data/backend/remote_repository.dart';
import '../../data/db/app_database.dart';
import '../../data/downloads/download_manager.dart';
import '../../data/providers.dart';
import '../player/player_screen.dart';
import 'device_picker.dart';
import 'remote_control_screen.dart';

/// The device a cast session targets. While set, [startPlayback] sends every
/// selected movie/episode/channel to that device instead of the local player.
final castTargetProvider =
    NotifierProvider<CastTargetController, RemoteDevice?>(
      CastTargetController.new,
    );

class CastTargetController extends Notifier<RemoteDevice?> {
  @override
  RemoteDevice? build() => null;

  void set(RemoteDevice? device) => state = device;
}

/// Central playback entry used by every "play this" flow. With a cast target
/// selected (and the item castable) the item starts on that device and the
/// remote opens; otherwise the local player opens. The returned future
/// completes when the pushed screen pops.
Future<void> startPlayback(
  BuildContext context,
  WidgetRef ref,
  PlayerArgs args,
) async {
  // The calling widget can unmount during the awaits below (nav rebuilds
  // dispose its element), which makes its `ref` unsafe — grab everything
  // up front.
  final castTarget = ref.read(castTargetProvider.notifier);
  final repository = ref.read(remoteRepositoryProvider);
  final device = ref.read(castTargetProvider);
  final sourceId = ref.read(activeSourceProvider).value?.id;
  final downloads = ref.read(downloadManagerProvider.notifier);
  final item = args.items[args.initialIndex];
  final identity = item.identity;
  if (device == null || identity == null) {
    final localArgs = sourceId == null
        ? args
        : await _preferLocalDownloads(downloads, sourceId, args);
    if (!context.mounted) return;
    await context.push('/player', extra: localArgs);
    return;
  }
  try {
    await repository.play(
      targetDeviceId: device.deviceId,
      identity: identity,
      positionSec: item.startAt?.inSeconds ?? 0,
    );
  } on RemoteException catch (error) {
    // A vanished target would swallow every play tap, so drop the session.
    castTarget.set(null);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${error.message} Casting turned off.')),
      );
    }
    return;
  }
  if (context.mounted) {
    await context.push('/remote', extra: RemoteControlArgs(device));
  }
}

/// Swaps each item's stream URL for its completed download, so anything
/// saved on this device plays offline no matter which screen started it.
Future<PlayerArgs> _preferLocalDownloads(
  DownloadManager downloads,
  int sourceId,
  PlayerArgs args,
) async {
  var changed = false;
  final items = <PlayerItem>[];
  for (final item in args.items) {
    final key = _downloadKey(item.identity);
    final local = key == null || item.live
        ? null
        : await downloads.localPath(sourceId, key.$1, key.$2);
    if (local == null) {
      items.add(item);
      continue;
    }
    changed = true;
    items.add(
      PlayerItem(
        url: local,
        title: item.title,
        subtitle: item.subtitle,
        startAt: item.startAt,
        identity: item.identity,
      ),
    );
  }
  if (!changed) return args;
  return PlayerArgs(
    items: items,
    initialIndex: args.initialIndex,
    onProgress: args.onProgress,
  );
}

(WatchKind, int)? _downloadKey(PlaybackIdentity? identity) {
  final id = switch (identity?.itemType) {
    'MOVIE' => int.tryParse(identity!.itemId),
    'SERIES' => int.tryParse(identity!.episodeId ?? ''),
    _ => null,
  };
  if (id == null) return null;
  return (
    identity!.itemType == 'MOVIE' ? WatchKind.movie : WatchKind.episode,
    id,
  );
}

/// Nav-bar cast button flow: no session picks a target device; an active
/// session offers opening the remote or disconnecting.
Future<void> showCastSheet(BuildContext context, WidgetRef ref) async {
  // Same unmount hazard as [startPlayback]: the button that opened the
  // sheet may be gone by the time a sheet item is tapped, so its `ref`
  // and `context` must not be touched from the callbacks.
  final castTarget = ref.read(castTargetProvider.notifier);
  final router = GoRouter.of(context);
  final current = ref.read(castTargetProvider);
  if (current == null) {
    final device = await showRemoteDevicePicker(
      context,
      ref,
      title: 'Cast to a device',
    );
    if (device == null || !context.mounted) return;
    castTarget.set(device);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Casting to ${device.displayName} — anything you play now '
          'starts there.',
        ),
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              current.isTv ? Icons.tv_rounded : Icons.cast_connected_rounded,
            ),
            title: Text(current.displayName),
            subtitle: const Text('Casting to this device'),
          ),
          ListTile(
            leading: const Icon(Icons.settings_remote_rounded),
            title: const Text('Open remote'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              unawaited(
                router.push('/remote', extra: RemoteControlArgs(current)),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.cast_rounded),
            title: const Text('Stop casting'),
            onTap: () {
              castTarget.set(null);
              Navigator.of(sheetContext).pop();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
