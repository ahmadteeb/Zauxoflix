import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_image.dart';
import '../../core/widgets/title_artwork.dart';
import '../../data/db/app_database.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/providers.dart';
import '../shell/navigation_glass.dart';
import 'player_screen.dart';

final _liveChannel = FutureProvider.autoDispose.family<LiveChannel?, int>((
  ref,
  id,
) {
  final source = ref.watch(activeSourceProvider).value;
  if (source == null) return null;
  return ref.watch(databaseProvider).getLiveChannel(source.id, id);
});

typedef _Broadcast = ({
  LiveChannel? channel,
  LiveStation? station,
  EpgProgramme? current,
  EpgProgramme? next,
});

final _broadcast = Provider.autoDispose.family<_Broadcast, int>((ref, id) {
  final channel = ref.watch(_liveChannel(id)).value;
  final sourceId = channel?.sourceId;
  final station = sourceId == null
      ? null
      : ref.watch(liveDirectoryProvider(sourceId)).value?.byStream[id];
  final guide = sourceId == null
      ? null
      : ref.watch(liveGuideIdsProvider(sourceId)).value?[station?.key] ??
            station?.guideId ??
            channel?.epgChannelId;
  final entries = sourceId != null && guide != null && guide.isNotEmpty
      ? ref.watch(liveScheduleProvider((sourceId, guide))).value
      : null;
  final now = DateTime.now();
  return (
    channel: channel,
    station: station,
    current: entries
        ?.where((e) => !e.startAt.isAfter(now) && e.endAt.isAfter(now))
        .firstOrNull,
    next: entries?.where((e) => e.startAt.isAfter(now)).firstOrNull,
  );
});

class PlayerChannelHeader extends ConsumerWidget {
  const PlayerChannelHeader({
    super.key,
    required this.item,
    required this.compact,
    required this.short,
    this.decodedHeight,
  });

  final PlayerItem item;
  final bool compact, short;
  final int? decodedHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = int.tryParse(item.identity?.itemId ?? '');
    final info = id == null ? null : ref.watch(_broadcast(id));
    final name = info?.station?.name ?? item.title;
    final logo = item.liveLogo ?? info?.station?.icon ?? info?.channel?.icon;
    final number = info?.channel?.channelNumber;
    final detail = item.subtitle.isNotEmpty
        ? item.subtitle
        : number == null
        ? null
        : 'CH $number';
    final quality = (decodedHeight ?? 0) > 0
        ? '${decodedHeight}p'
        : item.liveVersion;
    final metadata = [
      ?detail,
      if (quality != null && quality != LiveQuality.unknown.label) quality,
    ].join('  ·  ');
    final current = info?.current?.title.trim();
    final logoSize = short
        ? 40.0
        : compact
        ? 48.0
        : 68.0;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: compact ? 470 : 680),
        child: NavigationGlass(
          radius: compact ? 15 : 20,
          outlined: false,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(5, 5, compact ? 13 : 20, 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _StationMark(name: name, logo: logo, size: logoSize),
                SizedBox(width: compact ? 9 : 15),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 7,
                              color: Color(0xFFFF7E90),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Live',
                              style: TextStyle(
                                color: const Color(0xFFFFCCD4),
                                fontSize: compact ? 12 : 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (metadata.isNotEmpty)
                              Flexible(
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.only(
                                    start: 8,
                                  ),
                                  child: Text(
                                    metadata,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFFD5D2DE),
                                      fontSize: compact ? 12 : 14,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          name,
                          maxLines: short ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 20 : 30,
                            height: 1.16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!short && current != null && current.isNotEmpty)
                          Text(
                            'Now · $current',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: const Color(0xFFE4E1EA),
                              fontSize: compact ? 13 : 16,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StationMark extends StatelessWidget {
  const _StationMark({
    required this.name,
    required this.logo,
    required this.size,
  });
  final String name;
  final String? logo;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s.characters.first)
        .join()
        .toUpperCase();
    final mark = Stack(
      fit: StackFit.expand,
      children: [
        TitleArtwork(title: name, kind: ArtworkKind.live, hasCaption: true),
        Center(
          child: initials.isEmpty
              ? Icon(
                  Icons.cell_tower_rounded,
                  size: size * .48,
                  color: Colors.white,
                )
              : Text(
                  initials,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    fontSize: size * .45,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
    return ExcludeSemantics(
      child: SizedBox(
        width: size * 1.18,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * .19),
          child: logo?.trim().isNotEmpty == true
              ? DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF76747D), Color(0xFF5B5765)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AppImage(
                      url: logo!.trim(),
                      fit: BoxFit.contain,
                      memCacheWidth: (size * 3).round(),
                      placeholder: mark,
                      errorWidget: mark,
                    ),
                  ),
                )
              : mark,
        ),
      ),
    );
  }
}

class PlayerLiveInfo extends ConsumerWidget {
  const PlayerLiveInfo({super.key, required this.id, this.expanded = false});
  final int id;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final info = ref.watch(_broadcast(id));
    final current = info.current;
    final next = info.next;
    String clock(DateTime time) => MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(time.toLocal()));
    return Row(
      children: [
        if (info.channel case final channel?)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 10),
            child: _StationMark(
              name: info.station?.name ?? channel.name,
              logo: info.station?.icon ?? channel.icon,
              size: 40,
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (current != null)
                Text(
                  'Now · ${current.title}  ${clock(current.startAt)}–${clock(current.endAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (expanded && current != null)
                LinearProgressIndicator(
                  value:
                      (DateTime.now()
                                  .difference(current.startAt)
                                  .inMilliseconds /
                              current.endAt
                                  .difference(current.startAt)
                                  .inMilliseconds)
                          .clamp(0, 1),
                ),
              if (expanded && next != null)
                Text(
                  'Next · ${clock(next.startAt)}  ${next.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (expanded && current == null && next == null)
                Text(
                  'Schedule unavailable',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
