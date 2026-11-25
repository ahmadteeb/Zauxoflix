import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/app_sheet.dart';
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
  PlayerArgs args, {
  bool localOnly = false,
}) async {
  // The calling widget can unmount during the awaits below (nav rebuilds
  // dispose its element), which makes its `ref` unsafe — grab everything
  // up front.
  final castTarget = ref.read(castTargetProvider.notifier);
  final device = ref.read(castTargetProvider);
  final sourceId = ref.read(activeSourceProvider).value?.id;
  final downloads = ref.read(downloadManagerProvider.notifier);
  final item = args.items[args.initialIndex];
  final identity = item.identity;
  if (localOnly || device == null || identity == null) {
    final localArgs = localOnly || sourceId == null
        ? args
        : await preferLocalDownloads(downloads, sourceId, args);
    if (!context.mounted) return;
    if (GoRouterState.of(context).extra == playerDetailsOrigin) {
      context.pop(localArgs);
    } else {
      await context.push('/player', extra: localArgs);
    }
    return;
  }
  try {
    await ref
        .read(remoteRepositoryProvider)
        .play(
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
Future<PlayerArgs> preferLocalDownloads(
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
        episodeImage: item.episodeImage,
        seriesCover: item.seriesCover,
        containerExtension: item.containerExtension,
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

  final action = await showAppSheet<bool>(
    context,
    title: current.displayName,
    subtitle: 'Casting to this device',
    icon: Icons.cast_connected_rounded,
    body: (sheet) => Column(
      children: [
        AppSheetOption(
          icon: Icons.settings_remote_rounded,
          title: 'Open remote',
          autofocus: true,
          onPressed: () => Navigator.of(sheet).pop(true),
        ),
        AppSheetOption(
          icon: Icons.cast_rounded,
          title: 'Stop casting',
          onPressed: () => Navigator.of(sheet).pop(false),
        ),
      ],
    ),
  );
  if (!context.mounted || action == null) return;
  if (action) {
    unawaited(router.push('/remote', extra: RemoteControlArgs(current)));
  } else {
    castTarget.set(null);
  }
}
