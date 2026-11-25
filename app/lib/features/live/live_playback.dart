import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/input/input_modality.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/providers.dart';
import '../player/player_screen.dart';

class LiveVersionChoice {
  const LiveVersionChoice(this.streamId);
  final int? streamId;
}

Future<LiveVersionChoice?> chooseLiveVersion(
  BuildContext context,
  LiveStation station, {
  int? selected,
}) => showAppSheet<LiveVersionChoice>(
  context,
  title: 'Versions',
  surfaceColor: const Color(0xF31C192B),
  subtitle: station.name,
  icon: Icons.high_quality_outlined,
  body: (sheet) => Column(
    children: [
      AppSheetOption(
        icon: Icons.auto_awesome_outlined,
        title: 'Auto',
        detail: 'Use the last successful stream or a balanced quality',
        selected: selected == null,
        autofocus: selected == null && (kTvBuild || InputModality.usesDpad),
        onPressed: () => Navigator.pop(sheet, const LiveVersionChoice(null)),
      ),
      for (final (index, variant) in station.variants.indexed)
        AppSheetOption(
          icon: Icons.live_tv_outlined,
          title:
              variant.quality.label +
              (station.variants
                          .where((v) => v.quality == variant.quality)
                          .length >
                      1
                  ? ' · Feed ${index + 1}'
                  : ''),
          detail: variant.stream.name + (variant.hevc ? ' · HEVC' : ''),
          selected: selected == variant.stream.streamId,
          autofocus:
              selected == variant.stream.streamId &&
              (kTvBuild || InputModality.usesDpad),
          onPressed: () =>
              Navigator.pop(sheet, LiveVersionChoice(variant.stream.streamId)),
        ),
    ],
  ),
);

Future<void> saveLiveVersion(
  WidgetRef ref,
  LiveStation station,
  LiveVersionChoice choice,
) async {
  final viewer = ref.read(liveViewerProvider);
  if (viewer == null) return;
  await ref
      .read(databaseProvider)
      .saveLiveTuning(
        station.sourceId,
        viewer,
        station.key,
        preferred: Value(choice.streamId),
      );
}

PlayerItem? stationPlayerItem(
  LiveStation station,
  PlaybackUrls urls,
  LiveTuningData? tuning, {
  LiveVersionChoice? choice,
  int? tuneStream,
  bool allowFallback = true,
}) {
  final preferred = choice == null ? tuning?.preferredStream : choice.streamId;
  final order = station.tuneOrder(
    preferred: tuneStream ?? preferred,
    successful: tuning?.successfulStream,
  );
  final usable = order
      .where((version) => urls.live(version.stream) != null)
      .take(2)
      .toList();
  if (usable.isEmpty) return null;
  PlayerItem item(LiveVariant variant, {PlayerItem? alternate}) {
    final stream = variant.stream;
    return PlayerItem(
      url: urls.live(stream)!,
      title: station.name,
      subtitle: stream.channelNumber == null
          ? ''
          : 'CH ${stream.channelNumber}',
      live: true,
      identity: PlaybackIdentity(
        itemType: 'LIVE',
        itemId: stream.streamId.toString(),
      ),
      liveStationKey: station.key,
      liveLogo: station.icon,
      liveVersion: variant.quality.label,
      liveAlternate: alternate,
    );
  }

  final alternate = allowFallback && preferred == null && usable.length > 1
      ? item(usable[1])
      : null;
  return item(usable.first, alternate: alternate);
}

PlayerArgs? livePlayerQueue(
  List<LiveStation> stations,
  LiveStation selected,
  PlaybackUrls urls,
  Map<String, LiveTuningData> tuning, {
  LiveVersionChoice? choice,
  int? tuneStream,
  bool returnChannelId = false,
}) {
  final index = stations.indexWhere((station) => station.key == selected.key);
  // Keep a bounded channel-zapping window around the selection; the Channels
  // drawer can navigate beyond it without allocating thousands of URLs.
  final nearby = index < 0
      ? [selected]
      : stations.sublist(
          (index - 32).clamp(0, stations.length),
          (index + 33).clamp(0, stations.length),
        );
  final items = [
    for (final station in nearby)
      ?stationPlayerItem(
        station,
        urls,
        tuning[station.key],
        choice: station.key == selected.key ? choice : null,
        tuneStream: station.key == selected.key ? tuneStream : null,
      ),
  ];
  final selectedIndex = items.indexWhere(
    (item) => item.liveStationKey == selected.key,
  );
  return selectedIndex < 0
      ? null
      : PlayerArgs(
          items: items,
          initialIndex: selectedIndex,
          returnChannelId: returnChannelId,
        );
}

Future<void> toggleLiveFavorite(WidgetRef ref, LiveStation station) async {
  final db = ref.read(databaseProvider);
  final favorites = await db.allFavorites(station.sourceId);
  final saved = favorites
      .where(
        (favorite) =>
            favorite.kind == CatalogKind.live &&
            station.variants.any(
              (variant) => variant.stream.streamId == favorite.itemId,
            ),
      )
      .toList();
  if (saved.isEmpty) {
    await db.addFavorite(
      sourceId: station.sourceId,
      kind: CatalogKind.live,
      itemId: station.channel.streamId,
      name: station.name,
      imageUrl: station.icon,
    );
  } else {
    for (final favorite in saved) {
      await db.removeFavorite(
        station.sourceId,
        CatalogKind.live,
        favorite.itemId,
      );
    }
  }
}
