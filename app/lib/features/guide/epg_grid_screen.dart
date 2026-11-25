import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/input/input_modality.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tv/focusable.dart';
import '../../core/widgets/media_artwork.dart';
import '../../core/widgets/app_sheet.dart';
import '../../data/db/app_database.dart';
import '../../data/live/live_directory.dart';
import '../../data/live/live_providers.dart';
import '../../data/live/regional_channels.dart';
import '../../data/providers.dart';
import '../live/live_guide_mapping.dart';
import '../live/live_playback.dart';
import '../live/live_widgets.dart';
import '../remote/cast_session.dart';

const _pxPerMinute = 4.5;
const _headerHeight = 34.0;

/// Classic timeline TV guide: pinned channel column, horizontally scrolling
/// programme grid. Each visible row queries its own programmes, so memory
/// stays flat no matter how many channels or guide days exist.
class EpgGridScreen extends ConsumerStatefulWidget {
  const EpgGridScreen({super.key});

  @override
  ConsumerState<EpgGridScreen> createState() => _EpgGridScreenState();
}

class _EpgGridScreenState extends ConsumerState<EpgGridScreen> {
  late final DateTime _windowStart;
  late final DateTime _windowEnd;
  late final ScrollController _horizontal;
  final _leftVertical = ScrollController();
  final _rightVertical = ScrollController();
  Timer? _clock;
  DateTime _now = DateTime.now();
  bool _syncing = false;
  LiveRegion? _region;
  LiveGenre? _genre;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _windowStart = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
    ).subtract(const Duration(hours: 1));
    _windowEnd = _windowStart.add(const Duration(hours: 25));
    _horizontal = ScrollController(
      initialScrollOffset: (_offsetOf(now) - 160).clamp(0.0, double.infinity),
    );
    _leftVertical.addListener(() => _syncScroll(_leftVertical, _rightVertical));
    _rightVertical.addListener(
      () => _syncScroll(_rightVertical, _leftVertical),
    );
    _clock = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  void _syncScroll(ScrollController from, ScrollController to) {
    if (_syncing || !to.hasClients) return;
    _syncing = true;
    to.jumpTo(from.offset);
    _syncing = false;
  }

  @override
  void dispose() {
    _clock?.cancel();
    _horizontal.dispose();
    _leftVertical.dispose();
    _rightVertical.dispose();
    super.dispose();
  }

  double _offsetOf(DateTime time) =>
      time.difference(_windowStart).inSeconds / 60 * _pxPerMinute;

  double get _gridWidth => _offsetOf(_windowEnd);

  Future<void> _showProgrammeSheet(
    LiveChannel channel,
    EpgProgramme? programme,
    List<LiveStation> stations,
  ) async {
    final urls = ref.read(playbackUrlsProvider);
    final directory = ref.read(liveDirectoryProvider(channel.sourceId)).value;
    final station = directory?.byStream[channel.streamId];
    if (station == null || urls == null) return;
    final tuning =
        ref.read(liveTuningProvider(channel.sourceId)).value ??
        const <String, LiveTuningData>{};
    final args = livePlayerQueue(stations, station, urls, tuning);
    final action = await showAppSheet<String>(
      context,
      title: programme?.title ?? channel.name,
      subtitle: programme == null
          ? 'Schedule unavailable'
          : '${channel.name} · ${_formatTime(programme.startAt)}–${_formatTime(programme.endAt)}',
      icon: Icons.live_tv_rounded,
      body: (sheet) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (programme?.description case final description?)
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 14),
              child: Text(
                description,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          if (args != null)
            AppSheetOption(
              autofocus: InputModality.usesDpad,
              icon: Icons.play_arrow_rounded,
              title: 'Watch channel',
              onPressed: () => Navigator.of(sheet).pop('watch'),
            ),
          AppSheetOption(
            title: 'Match schedule',
            icon: Icons.calendar_month_rounded,
            onPressed: () => Navigator.of(sheet).pop('match'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'match') {
      await matchStationSchedule(context, ref, station, channel.epgChannelId);
    }
    if (action == 'watch' && args != null && mounted) {
      await startPlayback(context, ref, args);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeSourceProvider).value;
    final db = ref.watch(databaseProvider);
    if (source == null) return const SizedBox.shrink();
    final directory = ref.watch(liveDirectoryProvider(source.id));
    ref.watch(liveTuningProvider(source.id));
    final guideRevision = ref.watch(syncControllerProvider);
    final links =
        ref.watch(liveGuideIdsProvider(source.id)).value ??
        const <String, String>{};

    final formFactor = formFactorOf(context, ref);
    final compact = formFactor == FormFactor.mobile;
    final channelColWidth = compact ? 132.0 : 208.0;
    final scaler = MediaQuery.textScalerOf(context);
    // Both scrolling panes must give the title and airtime the same height.
    final rowHeight = math.max(
      60.0,
      24 + 1.55 * (scaler.scale(12) + scaler.scale(10)),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
              child: Row(
                children: [
                  Focusable(
                    autofocus: InputModality.usesDpad,
                    onSelect: () => context.pop(),
                    focusScale: 1.1,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TV Guide',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          MaterialLocalizations.of(
                            context,
                          ).formatFullDate(_now),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LiveFilterBar<LiveRegion?>(
                    options: [
                      (null, 'All regions'),
                      for (final r in LiveRegion.values) (r, r.label),
                    ],
                    selected: _region,
                    onSelect: (region) {
                      setState(() => _region = region);
                      if (region != null) {
                        ref.read(liveRegionProvider.notifier).select(region);
                      }
                    },
                  ),
                  LiveFilterBar<LiveGenre?>(
                    options: [
                      (null, 'All'),
                      for (final genre in LiveGenre.values)
                        (genre, genre.label),
                    ],
                    selected: _genre,
                    onSelect: (genre) => setState(() => _genre = genre),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Builder(
                builder: (context) {
                  final data = directory.value;
                  if (data == null && directory.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final all =
                      (_region == null
                          ? data?.stations
                          : data?.regional(_region!)) ??
                      const <LiveStation>[];
                  final stations = _genre == null
                      ? all
                      : all
                            .where((station) => station.genre == _genre)
                            .toList();
                  LiveChannel channelAt(int index) {
                    final station = stations[index];
                    return station.channel.copyWith(
                      name: station.name,
                      icon: Value(station.icon),
                      epgChannelId: Value(
                        links[station.key] ?? station.guideId,
                      ),
                    );
                  }

                  final channels = stations;
                  if (compact && channels.isNotEmpty) {
                    return ListView.builder(
                      key: ValueKey((_region, _genre)),
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                      itemCount: channels.length,
                      itemBuilder: (context, index) => _PhoneSchedule(
                        key: ValueKey(stations[index].key),
                        station: stations[index],
                        channel: channelAt(index),
                        onOpen: (programme) => _showProgrammeSheet(
                          channelAt(index),
                          programme,
                          stations,
                        ),
                      ),
                    );
                  }
                  if (channels.isEmpty) {
                    return const Center(
                      child: Text(
                        'No live channels yet',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: channelColWidth,
                        child: Column(
                          children: [
                            const SizedBox(height: _headerHeight),
                            Expanded(
                              child: ListView.builder(
                                controller: _leftVertical,
                                itemCount: channels.length,
                                itemExtent: rowHeight,
                                itemBuilder: (context, i) => _ChannelCell(
                                  channel: channelAt(i),
                                  compact: compact,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _horizontal,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: _gridWidth,
                            child: Stack(
                              children: [
                                Column(
                                  children: [
                                    _TimeHeader(
                                      windowStart: _windowStart,
                                      windowEnd: _windowEnd,
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                        controller: _rightVertical,
                                        itemCount: channels.length,
                                        itemExtent: rowHeight,
                                        itemBuilder: (context, i) =>
                                            _ProgrammeRow(
                                              key: ValueKey((
                                                channels[i].key,
                                                channelAt(i).epgChannelId,
                                                guideRevision,
                                              )),
                                              db: db,
                                              sourceId: source.id,
                                              channel: channelAt(i),
                                              windowStart: _windowStart,
                                              windowEnd: _windowEnd,
                                              now: _now,
                                              offsetOf: _offsetOf,
                                              gridWidth: _gridWidth,
                                              onProgrammeSelected: (p) =>
                                                  _showProgrammeSheet(
                                                    channelAt(i),
                                                    p,
                                                    stations,
                                                  ),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                // "Now" indicator across the whole grid.
                                Positioned(
                                  left: _offsetOf(_now),
                                  top: 0,
                                  bottom: 0,
                                  child: IgnorePointer(
                                    child: Container(
                                      width: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _PhoneSchedule extends ConsumerWidget {
  const _PhoneSchedule({
    super.key,
    required this.station,
    required this.channel,
    required this.onOpen,
  });
  final LiveStation station;
  final LiveChannel channel;
  final ValueChanged<EpgProgramme?> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? id = channel.epgChannelId;
    final now = DateTime.now();
    final programmes = id == null
        ? null
        : ref.watch(liveScheduleProvider((channel.sourceId, id))).value;
    final current = programmes
        ?.where((p) => !p.startAt.isAfter(now) && p.endAt.isAfter(now))
        .firstOrNull;
    final next = programmes?.where((p) => p.startAt.isAfter(now)).firstOrNull;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LiveStationRow(
              station: station,
              programme: current,
              onOpen: () => onOpen(current),
              trailing: IconButton(
                tooltip: 'Schedule options',
                icon: const Icon(Icons.more_horiz_rounded),
                onPressed: () => onOpen(current),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
              child: Text(
                next != null
                    ? 'Next · ${_formatTime(next.startAt)}  ${next.title}'
                    : current == null
                    ? 'Schedule unavailable'
                    : 'On now · until ${_formatTime(current.endAt)}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

class _TimeHeader extends StatelessWidget {
  const _TimeHeader({required this.windowStart, required this.windowEnd});

  final DateTime windowStart;
  final DateTime windowEnd;

  @override
  Widget build(BuildContext context) {
    final slots = <DateTime>[];
    for (
      var t = windowStart;
      t.isBefore(windowEnd);
      t = t.add(const Duration(minutes: 30))
    ) {
      slots.add(t);
    }
    return SizedBox(
      height: _headerHeight,
      child: Row(
        children: [
          for (final slot in slots)
            Container(
              width: 30 * _pxPerMinute,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 6),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: AppColors.surfaceLight),
                  bottom: BorderSide(color: AppColors.surfaceLight),
                ),
              ),
              child: Text(
                _formatTime(slot),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChannelCell extends StatelessWidget {
  const _ChannelCell({required this.channel, required this.compact});

  final LiveChannel channel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
      ),
      child: Row(
        children: [
          if (!compact)
            MediaArtwork(
              url: channel.icon,
              title: channel.name,
              kind: ArtworkKind.live,
              width: 42,
              height: 28,
              logo: true,
              cacheWidth: 84,
              icon: Icons.live_tv_rounded,
              radius: 6,
            ),
          if (!compact) const SizedBox(width: 8),
          Expanded(
            child: Text(
              channel.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgrammeRow extends StatefulWidget {
  const _ProgrammeRow({
    super.key,
    required this.db,
    required this.sourceId,
    required this.channel,
    required this.windowStart,
    required this.windowEnd,
    required this.now,
    required this.offsetOf,
    required this.gridWidth,
    required this.onProgrammeSelected,
  });

  final AppDatabase db;
  final int sourceId;
  final LiveChannel channel;
  final DateTime windowStart;
  final DateTime windowEnd;
  final DateTime now;
  final double Function(DateTime) offsetOf;
  final double gridWidth;
  final ValueChanged<EpgProgramme?> onProgrammeSelected;

  @override
  State<_ProgrammeRow> createState() => _ProgrammeRowState();
}

class _ProgrammeRowState extends State<_ProgrammeRow> {
  late final Future<List<EpgProgramme>> _programmes;

  @override
  void initState() {
    super.initState();
    final epgId = widget.channel.epgChannelId;
    _programmes = epgId == null
        ? Future.value(const <EpgProgramme>[])
        : widget.db.programmesFor(
            widget.sourceId,
            epgId,
            widget.windowStart,
            widget.windowEnd,
          );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _programmes,
      builder: (context, snapshot) {
        final programmes = snapshot.data ?? const <EpgProgramme>[];
        if (programmes.isEmpty) {
          return _emptyRow(snapshot.connectionState == ConnectionState.waiting);
        }
        return Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
          ),
          child: Stack(
            children: [
              for (final p in programmes)
                Positioned(
                  left: widget.offsetOf(
                    p.startAt.isBefore(widget.windowStart)
                        ? widget.windowStart
                        : p.startAt,
                  ),
                  width:
                      (widget.offsetOf(
                                p.endAt.isAfter(widget.windowEnd)
                                    ? widget.windowEnd
                                    : p.endAt,
                              ) -
                              widget.offsetOf(
                                p.startAt.isBefore(widget.windowStart)
                                    ? widget.windowStart
                                    : p.startAt,
                              ))
                          .clamp(_pxPerMinute, widget.gridWidth),
                  top: 3,
                  bottom: 4,
                  child: _ProgrammeCell(
                    programme: p,
                    airing:
                        !p.startAt.isAfter(widget.now) &&
                        p.endAt.isAfter(widget.now),
                    onSelect: () => widget.onProgrammeSelected(p),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyRow(bool loading) => Container(
    alignment: Alignment.centerLeft,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: AppColors.surfaceLight)),
    ),
    child: loading
        ? null
        : Padding(
            padding: EdgeInsets.only(
              left: (widget.offsetOf(widget.now) - 160).clamp(
                8.0,
                double.infinity,
              ),
            ),
            child: Focusable(
              onSelect: () => widget.onProgrammeSelected(null),
              focusScale: 1.02,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Schedule unavailable',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
  );
}

class _ProgrammeCell extends StatelessWidget {
  const _ProgrammeCell({
    required this.programme,
    required this.airing,
    required this.onSelect,
  });

  final EpgProgramme programme;
  final bool airing;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Focusable(
        onSelect: onSelect,
        focusScale: 1.0,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(
                width: 3,
                color: airing ? AppColors.primary : AppColors.surfaceLight,
              ),
            ),
            color: airing
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                programme.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_formatTime(programme.startAt)}–${_formatTime(programme.endAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
