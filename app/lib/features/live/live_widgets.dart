import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/media_artwork.dart';
import '../../data/db/app_database.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/live/regional_channels.dart';
import '../../data/providers.dart';
import '../home/widgets/home_remote_navigation.dart';
import '../remote/cast_session.dart';
import '../shell/navigation_glass.dart';
import 'live_playback.dart';
import 'sports_board.dart';

IconData stationIcon(LiveGenre? genre) => switch (genre) {
  LiveGenre.news => Icons.newspaper_rounded,
  LiveGenre.sports => Icons.sports_soccer_rounded,
  LiveGenre.entertainment => Icons.theaters_outlined,
  LiveGenre.kids => Icons.child_care_rounded,
  LiveGenre.factual => Icons.public_rounded,
  null => Icons.live_tv_rounded,
};

class LiveFilterBar<T> extends StatelessWidget {
  const LiveFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<(T, String)> options;
  final T selected;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final (id, name) in options)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 6),
            child: Semantics(
              selected: selected == id,
              child: TextButton(
                onPressed: () => onSelect(id),
                style: liveControlStyle(selected: selected == id, quiet: true),
                child: Text(name),
              ),
            ),
          ),
      ],
    ),
  );
}

ButtonStyle liveControlStyle({bool selected = false, bool quiet = false}) =>
    TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: quiet
              ? AppColors.surfaceLight.withValues(alpha: .35)
              : AppColors.controlSurface,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        )
        .copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: AppColors.focusRing, width: 2)
                : BorderSide.none,
          ),
        )
        .withSelectionGradient(selected);

class LiveStationRow extends StatelessWidget {
  const LiveStationRow({
    super.key,
    required this.station,
    required this.onOpen,
    this.programme,
    this.selected = false,
    this.sports = false,
    this.onFocus,
    this.onVersions,
    this.minutes,
    this.trailing,
  });

  final LiveStation station;
  final EpgProgramme? programme;
  final VoidCallback onOpen;
  final VoidCallback? onVersions;
  final ValueChanged<bool>? onFocus;
  final bool selected, sports;
  final int? minutes;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final versions = station.variants.length;
    final detail = [
      if (!sports) ?station.genre?.label,
      if (minutes case final count?)
        count < 1 ? 'Under 1 min' : '$count min watched',
      if (versions > 1) '$versions versions',
    ].join(' · ');
    final action =
        trailing ??
        (onVersions == null
            ? null
            : IconButton(
                onPressed: onVersions,
                icon: const Icon(Icons.tune_rounded, size: 20),
                tooltip: 'Versions for ${station.name}',
              ));
    final programmeColor = sports ? sportsMint : AppColors.selectionAccent;
    return LayoutBuilder(
      builder: (context, bounds) {
        final large = bounds.maxWidth >= 640;
        final logoWidth = large ? 96.0 : 72.0;
        final radius = BorderRadius.circular(16);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: selected
                  ? AppColors.selectionGradient
                  : sports
                  ? const LinearGradient(
                      colors: [Color(0xBC202D30), Color(0x88201F29)],
                    )
                  : AppColors.panelGradient,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    selected: selected,
                    child: TextButton(
                      onPressed: onOpen,
                      onFocusChange: onFocus,
                      style: liveControlStyle(quiet: true).copyWith(
                        alignment: AlignmentDirectional.centerStart,
                        backgroundColor: const WidgetStatePropertyAll(
                          Colors.transparent,
                        ),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        ),
                        shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(borderRadius: radius),
                        ),
                      ),
                      child: Row(
                        children: [
                          ExcludeSemantics(
                            child: MediaArtwork(
                              url: station.icon,
                              title: station.name,
                              kind: ArtworkKind.live,
                              width: logoWidth,
                              height: logoWidth * .68,
                              logo: true,
                              radius: 10,
                              cacheWidth: (logoWidth * 2).round(),
                              icon: sports
                                  ? Icons.sports_soccer_rounded
                                  : stationIcon(station.genre),
                            ),
                          ),
                          SizedBox(width: large ? 16 : 12),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  station.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: large ? 20 : 17,
                                    height: 1.13,
                                    letterSpacing: -.3,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (programme case final show?)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      show.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: large ? 15 : 13,
                                        color: programmeColor,
                                      ),
                                    ),
                                  ),
                                if (detail.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(
                                      detail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFFC3BFCB),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (selected)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                start: 6,
                              ),
                              child: Icon(
                                Icons.equalizer_rounded,
                                color: AppColors.selectionAccent,
                                size: 20,
                                semanticLabel: 'Now playing',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                ?action,
              ],
            ),
          ),
        );
      },
    );
  }
}

class LiveForYouRail extends ConsumerWidget {
  const LiveForYouRail({
    super.key,
    required this.sourceId,
    required this.formFactor,
  });
  final int sourceId;
  final FormFactor formFactor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendations = ref.watch(liveRecommendationsProvider(sourceId));
    final available = ref
        .watch(liveDirectoryProvider(sourceId))
        .value
        ?.stations;
    if (available == null || available.isEmpty) return const SizedBox.shrink();
    final stations = recommendations?.forYou;
    final shown = (stations == null || stations.isEmpty ? available : stations)
        .take(9)
        .toList();
    final links =
        ref.watch(liveGuideIdsProvider(sourceId)).value ??
        const <String, String>{};
    final tuning =
        ref.watch(liveTuningProvider(sourceId)).value ??
        const <String, LiveTuningData>{};
    final gutter = formFactor.gutter;
    return HomeFocusRow(
      key: const ValueKey('live-for-you'),
      railGutter: gutter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: gutter),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Live for you',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/live'),
                    child: const Text('Browse Live TV'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: formFactor.isTv ? 124 : 110,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                scrollDirection: Axis.horizontal,
                itemCount: shown.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final station = shown[index];
                  return SizedBox(
                    width: formFactor.isTv ? 276 : 224,
                    child: _LiveHomeCard(
                      station: station,
                      guideId: links[station.key] ?? station.guideId,
                      onOpen: () {
                        final urls = ref.read(playbackUrlsProvider);
                        if (urls == null) return;
                        final args = livePlayerQueue(
                          shown,
                          station,
                          urls,
                          tuning,
                        );
                        if (args != null) startPlayback(context, ref, args);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveHomeCard extends ConsumerWidget {
  const _LiveHomeCard({
    required this.station,
    required this.guideId,
    required this.onOpen,
  });
  final LiveStation station;
  final String? guideId;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ignore: deprecated_member_use
    final programmes = guideId == null || !TickerMode.of(context)
        ? null
        : ref.watch(liveScheduleProvider((station.sourceId, guideId!))).value;
    final now = DateTime.now();
    final current = programmes
        ?.where((item) => !item.startAt.isAfter(now) && item.endAt.isAfter(now))
        .firstOrNull;
    return NavigationGlass(
      radius: 14,
      child: TextButton(
        onPressed: onOpen,
        style:
            TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  width: 2,
                  color: states.contains(WidgetState.focused)
                      ? AppColors.focusRing
                      : Colors.transparent,
                ),
              ),
            ),
        child: Row(
          children: [
            MediaArtwork(
              url: station.icon,
              title: station.name,
              kind: ArtworkKind.live,
              cacheWidth: 120,
              width: 59,
              height: 66,
              logo: true,
              icon: stationIcon(station.genre),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    station.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    current?.title ?? station.genre?.label ?? 'Live channel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (current != null) ...[
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value:
                          now.difference(current.startAt).inSeconds /
                          current.endAt.difference(current.startAt).inSeconds,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
