import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/app_platform.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_sheet.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../core/widgets/media_artwork.dart';
import '../../core/widgets/skeleton.dart';
import '../../data/catalog_search.dart';
import '../../data/db/app_database.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/live/regional_channels.dart';
import '../../data/providers.dart';
import '../browse/category_dropdown.dart';
import '../player/playback_handoff.dart';
import '../player/playback_recovery.dart';
import '../player/player_screen.dart';
import '../player/player_volume.dart';
import '../remote/cast_session.dart';
import '../shell/navigation_glass.dart';
import '../shell/top_nav_bar.dart';
import 'live_playback.dart';
import 'live_widgets.dart';
import 'sports_board.dart';

enum _View {
  forYou('For You'),
  sports('Sports'),
  regional('Regional Picks'),
  all('All Channels'),
  favorites('Favorites'),
  recent('Recent'),
  watched('My Most Watched');

  const _View(this.label);
  final String label;
}

final _liveCategoriesProvider = StreamProvider.autoDispose
    .family<List<Category>, int>(
      (ref, sourceId) => ref
          .watch(databaseProvider)
          .watchCategories(sourceId, CatalogKind.live),
    );

typedef _SportsListing = ({
  List<LiveSportsSection> sections,
  List<LiveStation> stations,
  Set<String> keys,
});

// A focus change while moving down a long TV list must not rebuild its index.
final _sportsListingProvider = Provider.autoDispose
    .family<_SportsListing, (int, LiveSportsGroup?, String, int?)>((
      ref,
      filter,
    ) {
      final (sourceId, selected, search, number) = filter;
      final sections = <LiveSportsSection>[];
      final keys = <String>{};
      final stations = <LiveStation>[];
      for (final section in ref.watch(liveSportsProvider(sourceId))) {
        if (selected != null && section.group != selected) continue;
        final matches = [
          for (final station in section.stations)
            if ((search.isEmpty || station.matches(search, number)) &&
                keys.add(station.key))
              station,
        ];
        if (matches.isEmpty) continue;
        sections.add(LiveSportsSection(section.group, matches));
        stations.addAll(matches);
      }
      return (sections: sections, stations: stations, keys: keys);
    });

class LiveTvScreen extends ConsumerStatefulWidget {
  const LiveTvScreen({super.key});

  @override
  ConsumerState<LiveTvScreen> createState() => _LiveTvScreenState();
}

class _LiveTvScreenState extends ConsumerState<LiveTvScreen> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();
  _View _view = _View.forYou;
  LiveGenre? _genre;
  LiveSportsGroup? _sportsGroup;
  String? _category;
  String? _focused, _previewStation;
  PlayerItem? _previewItem;
  String _query = '';
  bool _suspended = false;
  bool _filtersOpen = false;
  Timer? _searchTimer;

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _filter(VoidCallback update) {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    setState(() {
      _focused = null;
      update();
    });
  }

  void _preview(LiveStation station, PlayerItem? item) {
    if (item == null || _suspended) return;
    setState(() {
      _previewStation = station.key;
      _previewItem = item;
    });
  }

  Future<void> _watch(PlayerArgs? args, {required bool previewLayout}) async {
    if (args == null || _suspended) return;
    if (!previewLayout || ref.read(castTargetProvider) != null) {
      await startPlayback(context, ref, args);
      return;
    }
    final sourceId = ref.read(activeSourceProvider).value?.id;
    setState(() => _suspended = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final tuned = await context.push<int>('/player', extra: args);
      if (!mounted ||
          sourceId == null ||
          ref.read(activeSourceProvider).value?.id != sourceId) {
        return;
      }
      final station = ref
          .read(liveDirectoryProvider(sourceId))
          .value
          ?.byStream[tuned];
      if (station == null) return;
      final urls = ref.read(playbackUrlsProvider);
      if (urls == null) return;
      _previewStation = station.key;
      _previewItem = stationPlayerItem(
        station,
        urls,
        ref.read(liveTuningProvider(sourceId)).value?[station.key],
        tuneStream: tuned,
      );
    } finally {
      if (mounted) setState(() => _suspended = false);
    }
  }

  Future<void> _guide() async {
    if (_suspended) return;
    setState(() => _suspended = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) await context.push('/guide');
    } finally {
      if (mounted) setState(() => _suspended = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(activeSourceProvider.select((s) => s.value?.id), (old, next) {
      if (old == null || old == next) return;
      _searchTimer?.cancel();
      _searchController.clear();
      _filter(() {
        _view = _View.forYou;
        _sportsGroup = null;
        _genre = null;
        _category = null;
        _filtersOpen = false;
        _previewStation = null;
        _previewItem = null;
        _query = '';
      });
    });
    final form = formFactorOf(context, ref);
    final source = ref.watch(activeSourceProvider).value;
    final urls = ref.watch(playbackUrlsProvider);
    if (source == null || urls == null) return const SizedBox.shrink();
    // ignore: deprecated_member_use
    final visible = TickerMode.of(context);
    final directory = ref.watch(liveDirectoryProvider(source.id));
    final all = directory.value?.stations ?? const <LiveStation>[];
    final ranked = ref.watch(liveRecommendationsProvider(source.id));
    final region = ref.watch(liveRegionProvider).value ?? LiveRegion.jordan;
    final tuning =
        ref.watch(liveTuningProvider(source.id)).value ??
        const <String, LiveTuningData>{};
    final guide =
        ref.watch(liveGuideIdsProvider(source.id)).value ??
        const <String, String>{};
    final nowPlaying = visible ? ref.watch(nowPlayingProvider).value : null;
    final casting = ref.watch(castTargetProvider) != null;
    final wide =
        form != FormFactor.mobile && MediaQuery.sizeOf(context).width >= 800;
    final phone = form == FormFactor.mobile;
    final categories = _view == _View.all
        ? ref.watch(_liveCategoriesProvider(source.id)).value ??
              const <Category>[]
        : const <Category>[];
    final search = catalogQuery(_query);
    final number = int.tryParse(search.replaceFirst(RegExp(r'^ch\s+'), ''));
    final sports = _view == _View.sports;
    final sportsSections = sports && visible
        ? ref.watch(liveSportsProvider(source.id))
        : const <LiveSportsSection>[];
    final group = sportsSections.any((s) => s.group == _sportsGroup)
        ? _sportsGroup
        : null;
    final listing = sports && visible
        ? ref.watch(_sportsListingProvider((source.id, group, search, number)))
        : null;
    final sections = listing?.sections ?? const <LiveSportsSection>[];
    var stations = !sports && search.isNotEmpty
        ? all
        : switch (_view) {
            _View.forYou =>
              ranked?.forYou.isNotEmpty == true ? ranked!.forYou : all,
            _View.regional =>
              directory.value?.regional(region) ?? const <LiveStation>[],
            _View.sports => listing?.stations ?? const <LiveStation>[],
            _View.all => all,
            _View.favorites => ranked?.favorites ?? const <LiveStation>[],
            _View.recent => ranked?.recent ?? const <LiveStation>[],
            _View.watched => ranked?.mostWatched ?? const <LiveStation>[],
          };
    if (_genre != null ||
        (_view == _View.all && _category != null) ||
        (!sports && search.isNotEmpty)) {
      stations = stations
          .where(
            (station) =>
                (_genre == null || station.genre == _genre) &&
                (_view != _View.all ||
                    _category == null ||
                    station.hasCategory(_category!)) &&
                (search.isEmpty || station.matches(search, number)),
          )
          .toList();
    }

    String? guideId(LiveStation station) =>
        guide[station.key] ?? station.guideId;
    EpgProgramme? programme(LiveStation station) =>
        nowPlaying?[guideId(station)];
    PlayerArgs? queue(
      LiveStation station, {
      LiveVersionChoice? choice,
      int? tuneStream,
    }) => livePlayerQueue(
      stations,
      station,
      urls,
      tuning,
      choice: choice,
      tuneStream: tuneStream,
      returnChannelId: wide,
    );
    void open(LiveStation station) {
      if (!wide || casting || station.key == _previewStation) {
        _watch(
          queue(
            station,
            tuneStream: station.key == _previewStation
                ? int.tryParse(_previewItem?.identity?.itemId ?? '')
                : null,
          ),
          previewLayout: wide,
        );
      } else {
        _preview(
          station,
          stationPlayerItem(station, urls, tuning[station.key]),
        );
      }
    }

    Future<void> versions(LiveStation station) async {
      final choice = await chooseLiveVersion(
        context,
        station,
        selected: tuning[station.key]?.preferredStream,
      );
      if (choice == null ||
          !mounted ||
          ref.read(activeSourceProvider).value?.id != source.id) {
        return;
      }
      await saveLiveVersion(ref, station, choice);
      if (!mounted) return;
      if (!wide || casting) {
        await _watch(queue(station, choice: choice), previewLayout: wide);
      } else {
        _preview(
          station,
          stationPlayerItem(station, urls, tuning[station.key], choice: choice),
        );
      }
    }

    LiveStation? visibleStation(String? key) {
      final station = directory.value?.byKey[key];
      if (sports &&
          station != null &&
          listing?.keys.contains(station.key) != true) {
        return null;
      }
      return station;
    }

    final preview = visibleStation(_previewStation);
    final focus = visibleStation(_focused) ?? preview ?? stations.firstOrNull;
    final display = preview ?? focus;
    final streamId = int.tryParse(_previewItem?.identity?.itemId ?? '');
    final stream = preview?.variants
        .where((v) => v.stream.streamId == streamId)
        .firstOrNull
        ?.stream;
    Widget channelRow(LiveStation station) => LiveStationRow(
      key: ValueKey(station.key),
      station: station,
      sports: sports,
      selected: station.key == _previewStation,
      programme: programme(station),
      minutes: _view == _View.watched ? ranked?.minutes[station.key] : null,
      onOpen: () => open(station),
      onFocus: wide
          ? (active) {
              if (active && _focused != station.key) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _focused = station.key);
                });
              }
            }
          : null,
      onVersions: wide && station.variants.length > 1
          ? () => versions(station)
          : null,
      trailing: wide
          ? null
          : PopupMenuButton<bool>(
              tooltip: 'Channel options',
              onSelected: (version) {
                if (version) {
                  versions(station);
                } else {
                  toggleLiveFavorite(ref, station);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: true, child: Text('Versions')),
                PopupMenuItem(
                  value: false,
                  child: Text(
                    ranked?.favorites.any(
                              (saved) => saved.key == station.key,
                            ) ==
                            true
                        ? 'Remove from Favorites'
                        : 'Add to Favorites',
                  ),
                ),
              ],
            ),
    );

    final list = directory.isLoading && !directory.hasValue
        ? const ChannelListSkeleton()
        : directory.hasError && !directory.hasValue
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                icon: Icons.live_tv_outlined,
                title: 'Couldn’t load channels',
                message: 'Try loading the library again.',
              ),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(liveDirectoryProvider(source.id)),
                child: const Text('Retry'),
              ),
            ],
          )
        : stations.isEmpty
        ? EmptyState(
            icon: Icons.live_tv_outlined,
            title: search.isNotEmpty
                ? 'No channels found'
                : switch (_view) {
                    _View.sports => 'No sports channels here yet',
                    _View.recent => 'No recent channels yet',
                    _View.favorites => 'No favorite channels yet',
                    _ => 'No channels here yet',
                  },
            message: _view == _View.watched
                ? 'Watch a live channel for at least 30 seconds to start your list.'
                : sports
                ? search.isNotEmpty
                      ? 'Try another channel name or number.'
                      : 'Sports channels appear here when your playlist includes them.'
                : 'Try another filter or browse All Channels.',
          )
        : sports
        ? CustomScrollView(
            controller: _scroll,
            slivers: [
              for (final section in sections) ...[
                SliverToBoxAdapter(
                  child: SportsGroupHeading(
                    group: section.group,
                    count: section.stations.length,
                    featured: section.group == sections.first.group,
                  ),
                ),
                SliverList.builder(
                  itemCount: section.stations.length,
                  itemBuilder: (_, index) =>
                      channelRow(section.stations[index]),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          )
        : ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: stations.length,
            itemBuilder: (_, index) => channelRow(stations[index]),
          );
    void selectView(_View view) {
      if (view == _view) return;
      _filter(() {
        if (view == _View.sports || _view == _View.sports) {
          _previewItem = null;
          _previewStation = null;
        }
        _view = view;
        _genre = null;
        _sportsGroup = null;
      });
    }

    Future<void> pickView() async {
      final choice = await showAppSheet<_View>(
        context,
        title: 'Channel lists',
        icon: Icons.live_tv_rounded,
        body: (sheet) => Column(
          children: [
            for (final view in _View.values)
              AppSheetOption(
                title: view.label,
                selected: view == _view,
                icon: switch (view) {
                  _View.forYou => Icons.auto_awesome_rounded,
                  _View.sports => Icons.sports_soccer_rounded,
                  _View.regional => Icons.public_rounded,
                  _View.all => Icons.grid_view_rounded,
                  _View.favorites => Icons.favorite_border_rounded,
                  _View.recent => Icons.history_rounded,
                  _View.watched => Icons.bar_chart_rounded,
                },
                onPressed: () => Navigator.pop(sheet, view),
              ),
          ],
        ),
      );
      if (mounted &&
          choice != null &&
          ref.read(activeSourceProvider).value?.id == source.id) {
        selectView(choice);
      }
    }

    final applied = [
      if (_view == _View.regional) region.label,
      ?group?.label,
      ?_genre?.label,
      if (_view == _View.all)
        ?categories
            .where((entry) => entry.categoryId == _category)
            .firstOrNull
            ?.name,
    ];
    final hasFilters = applied.isNotEmpty;
    final header = NavigationGlass(
      radius: 22,
      outlined: false,
      blur: phone && !isWebOsPlatform,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 5, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, bounds) => Row(
                children: [
                  Expanded(
                    child: Text(
                      'Live TV',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (phone && !sports)
                    Tooltip(
                      message: 'Open Sports',
                      child:
                          bounds.maxWidth >= 320 &&
                              MediaQuery.textScalerOf(context).scale(14) <= 18
                          ? TextButton.icon(
                              onPressed: () => selectView(_View.sports),
                              style: liveControlStyle(quiet: true),
                              icon: const Icon(
                                Icons.sports_soccer_rounded,
                                size: 18,
                                color: sportsMint,
                              ),
                              label: const Text('Sports'),
                            )
                          : IconButton(
                              onPressed: () => selectView(_View.sports),
                              style: liveControlStyle(quiet: true),
                              icon: const Icon(
                                Icons.sports_soccer_rounded,
                                size: 20,
                                color: sportsMint,
                              ),
                            ),
                    ),
                  if (phone && !sports) const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: _guide,
                    style: liveControlStyle(quiet: true),
                    icon: const Icon(Icons.calendar_view_day_rounded, size: 18),
                    label: const Text('TV Guide'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            if (!phone)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: LiveFilterBar(
                  options: [
                    for (final view in _View.values) (view, view.label),
                  ],
                  selected: _view,
                  onSelect: selectView,
                ),
              ),
            Row(
              children: [
                if (phone)
                  Expanded(
                    child: Tooltip(
                      message: 'Choose channel list',
                      child: TextButton(
                        style: liveControlStyle(selected: true),
                        onPressed: pickView,
                        child: Row(
                          children: [
                            Icon(
                              sports
                                  ? Icons.sports_soccer_rounded
                                  : Icons.layers_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                _view.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.expand_more_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(child: _channelSearch()),
                const SizedBox(width: 8),
                Semantics(
                  expanded: _filtersOpen,
                  child: TextButton.icon(
                    style: liveControlStyle(
                      selected: hasFilters || _filtersOpen,
                    ),
                    onPressed: () =>
                        setState(() => _filtersOpen = !_filtersOpen),
                    icon: Icon(
                      _filtersOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.tune_rounded,
                      size: 18,
                    ),
                    label: const Text('Filters'),
                  ),
                ),
              ],
            ),
            if (phone)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: _channelSearch(),
              ),
            if (!_filtersOpen && hasFilters)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 2,
                  top: 7,
                  end: 2,
                ),
                child: Text(
                  applied.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.selectionAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            AnimatedSize(
              alignment: Alignment.topCenter,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 190),
              curve: Curves.easeOutCubic,
              child: !_filtersOpen
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_view == _View.regional)
                            LiveFilterBar(
                              options: [
                                for (final entry in LiveRegion.values)
                                  (entry, entry.label),
                              ],
                              selected: region,
                              onSelect: (value) {
                                _filter(() {});
                                ref
                                    .read(liveRegionProvider.notifier)
                                    .select(value);
                              },
                            ),
                          if (sports)
                            LiveFilterBar<LiveSportsGroup?>(
                              options: [
                                (null, 'All groups'),
                                for (final section in sportsSections)
                                  (section.group, section.group.label),
                              ],
                              selected: group,
                              onSelect: (group) =>
                                  _filter(() => _sportsGroup = group),
                            )
                          else
                            LiveFilterBar<LiveGenre?>(
                              options: [
                                (null, 'All genres'),
                                for (final genre in LiveGenre.values)
                                  (genre, genre.label),
                              ],
                              selected: _genre,
                              onSelect: (genre) =>
                                  _filter(() => _genre = genre),
                            ),
                          if (_view == _View.all && categories.isNotEmpty)
                            CategoryDropdown(
                              formFactor: form,
                              categories: categories,
                              selectedId: _category,
                              onChanged: (id) => _filter(() => _category = id),
                              gutter: 0,
                              blended: true,
                            ),
                          if (group != null ||
                              _genre != null ||
                              (_view == _View.all && _category != null))
                            TextButton(
                              onPressed: () => _filter(() {
                                _genre = null;
                                _sportsGroup = null;
                                _category = null;
                              }),
                              style: liveControlStyle(quiet: true),
                              child: const Text('Clear filters'),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
    final gutter = phone ? 12.0 : form.gutter;
    final content = !wide
        ? list
        : Column(
            children: [
              Expanded(
                child: display == null || focus == null
                    ? list
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: list),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 7,
                            child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  SingleChildScrollView(
                                    child: _StationPreview(
                                      artworkHeight:
                                          (constraints.maxHeight - 160).clamp(
                                            120.0,
                                            500.0,
                                          ),
                                      station: display,
                                      focused: focus,
                                      guideId: visible ? guideId(focus) : null,
                                      playing: programme(focus),
                                      video:
                                          !visible ||
                                              _suspended ||
                                              casting ||
                                              _previewItem == null ||
                                              stream == null
                                          ? null
                                          : _MiniPlayer(
                                              key: ValueKey((
                                                source.id,
                                                stream.streamId,
                                              )),
                                              channel: stream,
                                              stationKey: display.key,
                                              url: _previewItem!.url,
                                              onFailure: () {
                                                if (_previewItem?.liveAlternate
                                                    case final next?) {
                                                  _preview(display, next);
                                                }
                                              },
                                            ),
                                      watch: () => _watch(
                                        queue(display, tuneStream: streamId),
                                        previewLayout: true,
                                      ),
                                      versions: () => versions(display),
                                      favorite:
                                          ranked?.favorites.any(
                                            (station) =>
                                                station.key == display.key,
                                          ) ==
                                          true,
                                      toggleFavorite: () =>
                                          toggleLiveFavorite(ref, display),
                                    ),
                                  ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          );
    return Padding(
      padding: EdgeInsets.fromLTRB(
        gutter,
        phone ? 6 : kTopNavHeight + 10,
        gutter,
        0,
      ),
      child: FocusTraversalGroup(
        child: LayoutBuilder(
          builder: (context, bounds) {
            final split =
                phone &&
                bounds.maxWidth >= 610 &&
                MediaQuery.orientationOf(context) == Orientation.landscape;
            if (split) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: (bounds.maxWidth * .36).clamp(218.0, 306.0),
                    child: SingleChildScrollView(child: header),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: content),
                ],
              );
            }
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: bounds.maxHeight * (phone ? .65 : .60),
                  ),
                  child: SingleChildScrollView(child: header),
                ),
                const SizedBox(height: 8),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _channelSearch() => DpadTextField(
    borderRadius: BorderRadius.circular(14),
    builder: (context, fieldNode) => TextField(
      controller: _searchController,
      focusNode: fieldNode,
      textInputAction: TextInputAction.search,
      onChanged: (text) {
        _searchTimer?.cancel();
        _searchTimer = Timer(const Duration(milliseconds: 160), () {
          if (mounted) _filter(() => _query = text.trim());
        });
      },
      decoration: InputDecoration(
        isDense: true,
        hintText: _view == _View.sports
            ? 'Search sports channels'
            : 'Search channels',
        filled: true,
        fillColor: AppColors.controlSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchTimer?.cancel();
                  _searchController.clear();
                  _filter(() => _query = '');
                },
              ),
      ),
    ),
  );
}

class _StationPreview extends ConsumerWidget {
  const _StationPreview({
    required this.station,
    required this.focused,
    required this.artworkHeight,
    required this.guideId,
    required this.playing,
    required this.video,
    required this.watch,
    required this.versions,
    required this.favorite,
    required this.toggleFavorite,
  });
  final LiveStation station, focused;
  final double artworkHeight;
  final String? guideId;
  final EpgProgramme? playing;
  final Widget? video;
  final VoidCallback watch, versions, toggleFavorite;
  final bool favorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = guideId == null
        ? null
        : ref
              .watch(liveScheduleProvider((focused.sourceId, guideId!)))
              .value
              ?.where((show) => show.startAt.isAfter(DateTime.now()))
              .firstOrNull;
    return NavigationGlass(
      radius: 22,
      outlined: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: artworkHeight,
            width: double.infinity,
            child:
                video ??
                MediaArtwork(
                  url: station.icon,
                  title: station.name,
                  kind: ArtworkKind.live,
                  logo: true,
                  cacheWidth: 580,
                  icon: stationIcon(station.genre),
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (station.key != focused.key)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      focused.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                const SizedBox(height: 5),
                Text(
                  playing == null
                      ? next == null
                            ? 'Schedule unavailable'
                            : 'Nothing scheduled now'
                      : 'On now · ${playing!.title}',
                ),
                if (next != null)
                  Text(
                    'Next · ${next.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilledButton.icon(
                      onPressed: watch,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Watch'),
                    ),
                    TextButton.icon(
                      style: liveControlStyle(),
                      onPressed: versions,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Versions'),
                    ),
                    IconButton.filledTonal(
                      style: liveControlStyle(),
                      onPressed: toggleFavorite,
                      tooltip: favorite
                          ? 'Remove from Favorites'
                          : 'Add to Favorites',
                      icon: Icon(
                        favorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        semanticLabel: favorite
                            ? 'Remove from Favorites'
                            : 'Add to Favorites',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniPlayer extends ConsumerStatefulWidget {
  const _MiniPlayer({
    super.key,
    required this.url,
    required this.channel,
    required this.stationKey,
    this.onFailure,
  });
  final LiveChannel channel;
  final String url, stationKey;
  final VoidCallback? onFailure;

  @override
  ConsumerState<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends ConsumerState<_MiniPlayer>
    with WidgetsBindingObserver {
  late final PlaybackHandoff _handoff;
  PlaybackSession? _session;
  PlaybackRecovery? _recovery;
  double? _decoderAspect;
  String? _error;
  bool _recorded = false;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _handoff = ref.read(playbackHandoffProvider);
    final state = WidgetsBinding.instance.lifecycleState;
    _hidden =
        state == AppLifecycleState.hidden || state == AppLifecycleState.paused;
    if (!_hidden) _startPlayback();
  }

  void _startPlayback() {
    _recovery = _handoff.begin(
      url: widget.url,
      live: true,
      webOs: isWebOsPlatform,
      reopen: () => unawaited(_openDecoder()),
      onFailure: (reason) {
        if (!mounted) return;
        _release();
        setState(() => _error = reason);
        widget.onFailure?.call();
      },
    );
    unawaited(_openDecoder());
  }

  void _release() {
    _session?.controller.removeListener(_observe);
    _session?.close();
    _session = null;
    _decoderAspect = null;
  }

  void _observe() {
    final session = _session;
    if (session != null && session.current) {
      final value = session.controller.value;
      if (value.isInitialized) _decoderAspect = value.aspectRatio;
      _recovery?.observe(value);
    }
  }

  Future<void> _openDecoder() async {
    _release();
    final recovery = _recovery!;
    final session = _session = _handoff.select(
      VideoPlayerController.networkUrl(Uri.parse(widget.url)),
    );
    session.controller.addListener(_observe);
    setState(() => _error = null);
    try {
      final ready = await session.initialize(
        live: true,
        volume: isWebOsPlatform ? null : ref.read(playerVolumeProvider),
      );
      if (!ready || !mounted || !session.current) return;
      await session.controller.play();
      if (!mounted || !session.current) return;
      recovery.playing(session.controller.value);
      final db = ref.read(databaseProvider);
      if (ref.read(liveViewerProvider) case final viewer?) {
        session.trackLive(
          db,
          widget.channel.sourceId,
          viewer,
          widget.channel.streamId,
          widget.stationKey,
        );
      }
      if (!_recorded && !session.controller.value.hasError) {
        _recorded = true;
        db
            .recordLivePlayback(
              widget.channel.sourceId,
              widget.channel.streamId,
            )
            .ignore();
      }
    } catch (error) {
      if (mounted && identical(session, _session)) recovery.failure(error);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_hidden &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden)) {
      _hidden = true;
      if (_recovery case final recovery?) _handoff.end(recovery);
      _release();
      setState(() {});
    } else if (_hidden && state == AppLifecycleState.resumed) {
      _hidden = false;
      if (_error == null) _startPlayback();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_recovery case final recovery?) _handoff.end(recovery);
    _release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isWebOsPlatform) {
      ref.listen(playerVolumeProvider, (_, volume) {
        _session?.controller.setVolume(volume);
      });
    }
    final controller = _session?.controller;
    Widget retry() => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Playback failed. Try a different version.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          TextButton(onPressed: _startPlayback, child: const Text('Retry')),
        ],
      ),
    );
    return ColoredBox(
      color: Colors.black,
      child: _error != null
          ? retry()
          : controller == null
          ? const SizedBox.expand()
          : ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, value, _) {
                final aspect = value.isInitialized
                    ? value.aspectRatio
                    : _decoderAspect;
                if (aspect == null) {
                  if (_recovery?.hasPlayed == true) {
                    return const SizedBox.expand();
                  }
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  );
                }
                return Center(
                  child: AspectRatio(
                    aspectRatio: aspect > 0 ? aspect : 16 / 9,
                    child: VideoPlayer(controller),
                  ),
                );
              },
            ),
    );
  }
}
