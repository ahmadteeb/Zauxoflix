import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/input/input_modality.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../../core/tv/focusable.dart';
import '../../core/widgets/app_image.dart';
import '../../data/backend/remote_models.dart';
import '../../data/db/app_database.dart';
import '../../data/providers.dart';
import '../player/player_screen.dart';
import '../remote/cast_session.dart';

const _pxPerMinute = 4.5;
const _rowHeight = 60.0;
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
  ) async {
    final urls = ref.read(playbackUrlsProvider);
    final url = urls?.live(channel);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                programme?.title ?? channel.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                programme == null
                    ? channel.name
                    : '${channel.name}  ·  ${_formatTime(programme.startAt)}–${_formatTime(programme.endAt)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              if (programme?.description case final d?) ...[
                const SizedBox(height: 12),
                Text(
                  d,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (url != null) ...[
                const SizedBox(height: 18),
                FilledButton.icon(
                  autofocus: InputModality.usesDpad,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    startPlayback(
                      context,
                      ref,
                      PlayerArgs.single(
                        url: url,
                        title: channel.name,
                        subtitle: programme?.title ?? '',
                        live: true,
                        identity: PlaybackIdentity(
                          itemType: 'LIVE',
                          itemId: '${channel.streamId}',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Watch channel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(activeSourceProvider).value;
    final db = ref.watch(databaseProvider);
    if (source == null) return const SizedBox.shrink();

    final formFactor = formFactorOf(context, ref);
    final compact = formFactor == FormFactor.mobile;
    final channelColWidth = compact ? 132.0 : 208.0;

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
            Expanded(
              child: StreamBuilder(
                stream: db.watchLiveChannels(source.id, limit: null),
                builder: (context, snapshot) {
                  final channels = snapshot.data ?? const <LiveChannel>[];
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
                                itemExtent: _rowHeight,
                                itemBuilder: (context, i) => _ChannelCell(
                                  channel: channels[i],
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
                                        itemExtent: _rowHeight,
                                        itemBuilder: (context, i) =>
                                            _ProgrammeRow(
                                              key: ValueKey(
                                                channels[i].streamId,
                                              ),
                                              db: db,
                                              sourceId: source.id,
                                              channel: channels[i],
                                              windowStart: _windowStart,
                                              windowEnd: _windowEnd,
                                              now: _now,
                                              offsetOf: _offsetOf,
                                              gridWidth: _gridWidth,
                                              onProgrammeSelected: (p) =>
                                                  _showProgrammeSheet(
                                                    channels[i],
                                                    p,
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
            SizedBox(
              width: 42,
              height: 26,
              child: channel.icon == null
                  ? const Icon(
                      Icons.live_tv_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    )
                  : AppImage(
                      url: channel.icon!,
                      fit: BoxFit.contain,
                      memCacheWidth: 84,
                      placeholderIconSize: 14,
                      errorWidget: const Icon(
                        Icons.live_tv_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
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
                  'No guide data',
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
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: airing
                ? AppColors.primary.withValues(alpha: 0.22)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(6),
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
