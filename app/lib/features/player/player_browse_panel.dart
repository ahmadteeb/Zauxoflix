import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/catalog_row_card.dart';
import '../../data/db/app_database.dart';
import '../../data/catalog_search.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/providers.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../live/live_playback.dart';
import '../live/live_widgets.dart';
import '../shell/navigation_glass.dart';
import 'player_catalog.dart';
import 'player_screen.dart';

enum _ChannelTab { all, sports, recent, favorites }

class PlayerPanelMemory {
  int? season;
  _ChannelTab _channelTab = _ChannelTab.all;
  final offsets = <Object, double>{};
}

Future<PlayerArgs?> showPlayerBrowsePanel(
  BuildContext context,
  PlayerArgs queue,
  int index,
  int sourceId,
  PlayerPanelMemory memory, {
  int? decodedHeight,
}) async {
  final live = queue.items[index].live;
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  final route = RawDialogRoute<PlayerArgs>(
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: const Color(0x8A07070E),
    transitionDuration: reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 160),
    pageBuilder: (context, _, _) {
      final size = MediaQuery.sizeOf(context);
      final wide =
          size.width >= 700 || (size.width >= 580 && size.width > size.height);
      return Align(
        alignment: wide
            ? AlignmentDirectional.centerEnd
            : Alignment.bottomCenter,
        child: SafeArea(
          minimum: const EdgeInsets.all(8),
          child: SizedBox(
            width: wide ? (size.width * .40).clamp(342.0, 530.0) : size.width,
            height: wide ? size.height : size.height * .79,
            child: NavigationGlass(
              radius: 24,
              outlined: false,
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppSheetHeader(
                      title: live ? 'Channels' : 'Episodes',
                      subtitle: queue.items[index].title,
                      icon: live
                          ? Icons.live_tv_rounded
                          : Icons.video_library_outlined,
                    ),
                    Expanded(
                      child: live
                          ? _Channels(
                              queue: queue,
                              index: index,
                              decodedHeight: decodedHeight,
                              sourceId: sourceId,
                              memory: memory,
                            )
                          : _Episodes(
                              queue: queue,
                              index: index,
                              sourceId: sourceId,
                              memory: memory,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  final choice = await Navigator.of(context, rootNavigator: true).push(route);
  await route.completed;
  return choice;
}

class _Episodes extends ConsumerStatefulWidget {
  const _Episodes({
    required this.queue,
    required this.index,
    required this.sourceId,
    required this.memory,
  });
  final PlayerArgs queue;
  final int index, sourceId;
  final PlayerPanelMemory memory;
  @override
  ConsumerState<_Episodes> createState() => _EpisodesState();
}

class _EpisodesState extends ConsumerState<_Episodes> {
  PlayerItem get item => widget.queue.items[widget.index];
  int get seriesId => int.parse(item.identity!.itemId);
  late final positions = ref
      .read(databaseProvider)
      .watchSeriesPositions(widget.sourceId, seriesId);
  late final series = ref
      .read(databaseProvider)
      .getSeriesItem(widget.sourceId, seriesId);

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(playerSeriesProvider(seriesId));
    final seasons = data.value?.seasons ?? {};
    final numbers = seasons.keys.toList()..sort();
    final activeId = int.tryParse(item.identity?.episodeId ?? '');
    final activeSeason = numbers
        .where((s) => seasons[s]!.any((e) => e.id == activeId))
        .firstOrNull;
    final selected = numbers.contains(widget.memory.season)
        ? widget.memory.season
        : activeSeason ?? numbers.firstOrNull;
    final episodes = seasons[selected];
    return StreamBuilder(
      stream: positions,
      builder: (context, snapshot) {
        final saved = {
          for (final p in snapshot.data ?? <PlaybackPosition>[])
            if (!p.isCompletedEpisode) p.itemId: p,
        };
        final current =
            episodes?.indexWhere((e) => e.id == activeId) ?? widget.index;
        final group = selected ?? -1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (selected != null)
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 6),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.expand_more_rounded),
                  label: Text('Season $selected'),
                  onPressed: () async {
                    final choice = await showAppSheet<int>(
                      context,
                      title: 'Select season',
                      subtitle: item.title,
                      icon: Icons.video_library_outlined,
                      body: (sheet) => Column(
                        children: [
                          for (final n in numbers)
                            AppSheetOption(
                              title: 'Season $n',
                              detail:
                                  '${seasons[n]!.length} ${seasons[n]!.length == 1 ? 'episode' : 'episodes'}',
                              selected: n == selected,
                              autofocus: n == selected,
                              onPressed: () => Navigator.pop(sheet, n),
                            ),
                        ],
                      ),
                    );
                    if (mounted && choice != null) {
                      setState(() => widget.memory.season = choice);
                    }
                  },
                ),
              ),
            if (data.isLoading && episodes == null)
              const LinearProgressIndicator(),
            if (data.hasError)
              TextButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Retry loading seasons'),
                onPressed: () => ref.invalidate(playerSeriesProvider(seriesId)),
              ),
            Expanded(
              child: _PanelList(
                key: ValueKey(group),
                memory: widget.memory,
                group: group,
                current: current,
                count: episodes?.length ?? widget.queue.items.length,
                builder: (context, i) {
                  final e = episodes?[i];
                  final fallback = e == null ? widget.queue.items[i] : null;
                  final id =
                      e?.id ??
                      int.tryParse(fallback?.identity?.episodeId ?? '');
                  final pos = saved[id];
                  return CatalogRowCard(
                    title:
                        e?.title ??
                        (fallback!.subtitle.isEmpty
                            ? fallback.title
                            : fallback.subtitle),
                    caption: e == null
                        ? null
                        : [
                            'Episode ${e.episodeNum}',
                            if (e.durationText?.isNotEmpty == true)
                              e.durationText!,
                          ].join('  ·  '),
                    description: e?.plot,
                    image: e?.image,
                    icon: Icons.movie_outlined,
                    selected: i == current,
                    autofocus: i == current,
                    previewDescription: true,
                    progress: pos != null && pos.durationSecs > 0
                        ? pos.positionSecs / pos.durationSecs
                        : null,
                    onSelect: () async {
                      final nav = Navigator.of(context);
                      if (i == current) {
                        nav.pop();
                        return;
                      }
                      if (e == null) {
                        final items = [...widget.queue.items];
                        items[i] = items[i].withStartAt(
                          pos == null
                              ? null
                              : Duration(seconds: pos.positionSecs),
                        );
                        nav.pop(
                          PlayerArgs(
                            items: items,
                            initialIndex: i,
                            onProgress: widget.queue.onProgress,
                          ),
                        );
                        return;
                      }
                      final api = ref.read(xtreamApiProvider);
                      final resume = ref.read(resumeServiceProvider);
                      final model = await series;
                      if (!context.mounted ||
                          ModalRoute.of(context)?.isCurrent != true) {
                        return;
                      }
                      if (api == null ||
                          model == null ||
                          ref.read(activeSourceProvider).value?.id !=
                              widget.sourceId) {
                        return;
                      }
                      nav.pop(
                        seasonPlayback(
                          api,
                          model,
                          episodes!,
                          i,
                          resume,
                          position: pos,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Channels extends ConsumerStatefulWidget {
  const _Channels({
    required this.queue,
    required this.index,
    required this.sourceId,
    required this.memory,
    required this.decodedHeight,
  });
  final PlayerArgs queue;
  final int index, sourceId;
  final int? decodedHeight;
  final PlayerPanelMemory memory;
  @override
  ConsumerState<_Channels> createState() => _ChannelsState();
}

class _ChannelsState extends ConsumerState<_Channels> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final item = widget.queue.items[widget.index];
    final rawId = int.tryParse(item.identity?.itemId ?? '');
    final urls = ref.watch(playbackUrlsProvider);
    final directory = ref.watch(liveDirectoryProvider(widget.sourceId));
    final current = directory.value?.byStream[rawId];
    final tab = widget.memory._channelTab;
    final sports = tab == _ChannelTab.sports;
    final guideLinks = sports
        ? ref.watch(liveGuideIdsProvider(widget.sourceId)).value
        : null;
    final nowPlaying = sports ? ref.watch(nowPlayingProvider).value : null;
    final tuning =
        ref.watch(liveTuningProvider(widget.sourceId)).value ??
        const <String, LiveTuningData>{};
    final filter = catalogQuery(query);
    final all = directory.value?.stations ?? const <LiveStation>[];
    final seen = <String>{};
    final available = switch (tab) {
      _ChannelTab.all => all,
      _ChannelTab.sports => [
        for (final section in ref.watch(liveSportsProvider(widget.sourceId)))
          for (final station in section.stations)
            if (seen.add(station.key)) station,
      ],
      _ChannelTab.recent =>
        ref.watch(liveRecommendationsProvider(widget.sourceId))?.recent ??
            const <LiveStation>[],
      _ChannelTab.favorites =>
        ref.watch(liveRecommendationsProvider(widget.sourceId))?.favorites ??
            const <LiveStation>[],
    };
    final rows = filter.isEmpty
        ? available
        : available
              .where((station) => station.matches(filter, int.tryParse(filter)))
              .toList();

    Future<void> versions(LiveStation station) async {
      if (urls == null) return;
      final record = tuning[station.key];
      final choice = await chooseLiveVersion(
        context,
        station,
        selected: record?.preferredStream,
      );
      if (choice == null || !context.mounted) return;
      await saveLiveVersion(ref, station, choice);
      if (!context.mounted) return;
      final chosen = stationPlayerItem(station, urls, record, choice: choice);
      if (chosen == null) return;
      Navigator.pop(
        context,
        PlayerArgs(
          items: [...widget.queue.items]..[widget.index] = chosen,
          initialIndex: widget.index,
          returnChannelId: widget.queue.returnChannelId,
          onProgress: widget.queue.onProgress,
        ),
      );
    }

    final height = widget.decodedHeight ?? 0;
    final format = height > 0 ? '${height}p' : item.liveVersion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (rawId != null && MediaQuery.sizeOf(context).height >= 365)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 10),
            child: PlayerLiveInfo(id: rawId, expanded: true),
          ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton.icon(
              style: liveControlStyle(),
              onPressed: () => versions(current),
              icon: const Icon(Icons.tune_rounded),
              label: Text(format == null ? 'Versions' : 'Versions · $format'),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LiveFilterBar(
            options: const [
              (_ChannelTab.all, 'All Channels'),
              (_ChannelTab.sports, 'Sports'),
              (_ChannelTab.recent, 'Recent'),
              (_ChannelTab.favorites, 'Favorites'),
            ],
            selected: tab,
            onSelect: (choice) =>
                setState(() => widget.memory._channelTab = choice),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 5),
          child: DpadTextField(
            builder: (context, node) => TextField(
              focusNode: node,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Find a channel',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
        ),
        if (directory.isLoading && !directory.hasValue)
          const LinearProgressIndicator()
        else if (rows.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                directory.hasError
                    ? 'Unable to load channels'
                    : filter.isNotEmpty
                    ? 'No channels found'
                    : sports
                    ? 'No sports channels in this playlist'
                    : 'No channels in this list',
              ),
            ),
          )
        else
          Expanded(
            child: _PanelList(
              key: ValueKey((tab, filter)),
              memory: widget.memory,
              group: filter.isEmpty ? tab : (tab, filter),
              current: rows.indexWhere(
                (station) => station.key == current?.key,
              ),
              count: rows.length,
              builder: (context, index) {
                final station = rows[index];
                final programme =
                    nowPlaying?[guideLinks?[station.key] ?? station.guideId];
                final now = DateTime.now();
                return LiveStationRow(
                  key: ValueKey(station.key),
                  station: station,
                  programme:
                      programme != null &&
                          programme.sourceId == widget.sourceId &&
                          !programme.startAt.isAfter(now) &&
                          programme.endAt.isAfter(now)
                      ? programme
                      : null,
                  selected: station.key == current?.key,
                  onOpen: () {
                    if (urls == null) return;
                    if (station.key == current?.key && height > 0) {
                      Navigator.pop(context);
                      return;
                    }
                    if (sports) {
                      final existing = widget.queue.items.indexWhere((entry) {
                        final id = int.tryParse(entry.identity?.itemId ?? '');
                        return (entry.liveStationKey ??
                                directory.value?.byStream[id]?.key) ==
                            station.key;
                      });
                      if (existing >= 0) {
                        Navigator.pop(
                          context,
                          PlayerArgs(
                            items: widget.queue.items,
                            initialIndex: existing,
                            returnChannelId: widget.queue.returnChannelId,
                            onProgress: widget.queue.onProgress,
                          ),
                        );
                        return;
                      }
                    }
                    final args = livePlayerQueue(
                      rows,
                      station,
                      urls,
                      tuning,
                      returnChannelId: widget.queue.returnChannelId,
                    );
                    if (args != null) Navigator.pop(context, args);
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _PanelList extends StatefulWidget {
  const _PanelList({
    super.key,
    required this.memory,
    required this.group,
    required this.current,
    required this.count,
    required this.builder,
  });
  final PlayerPanelMemory memory;
  final Object group;
  final int current, count;
  final IndexedWidgetBuilder builder;
  @override
  State<_PanelList> createState() => _PanelListState();
}

class _PanelListState extends State<_PanelList> {
  ScrollController? controller;
  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = MediaQuery.textScalerOf(context).scale(16) > 22
        ? 146.0
        : 112.0;
    controller ??= ScrollController(
      initialScrollOffset:
          widget.memory.offsets[widget.group] ??
          (widget.current > 0 ? widget.current * extent : 0),
    );
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        widget.memory.offsets[widget.group] = n.metrics.pixels;
        return false;
      },
      child: ListView.builder(
        controller: controller,
        itemExtent: extent,
        itemCount: widget.count,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        itemBuilder: widget.builder,
      ),
    );
  }
}
