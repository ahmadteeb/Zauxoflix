import 'dart:async';

import 'package:flutter/material.dart';
import '../../../data/discovery/home_ranking.dart';
import '../../../data/discovery/actor_library.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/media_item.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/tv/focusable.dart';
import '../../../core/widgets/media_artwork.dart';
import 'catalog_card_preview.dart';

class PosterCard extends StatefulWidget {
  const PosterCard({
    super.key,
    required this.item,
    required this.width,
    this.wide = false,
    this.tvNavigation = false,
    this.rank,
    this.onSelect,
    this.onRemove,
    this.onDetails,
  });
  final MediaItem item;
  final double width;
  final bool wide, tvNavigation;
  final int? rank;
  final VoidCallback? onSelect, onRemove, onDetails;

  static bool dismissVisiblePreview() {
    final card = _PosterCardState._activePreview;
    if (card == null || !card.mounted || !card._routeVisible) return false;
    card._dismissed = true;
    card._hide();
    return true;
  }

  @override
  State<PosterCard> createState() => _PosterCardState();
}

class _PosterCardState extends State<PosterCard> {
  static _PosterCardState? _activePreview;
  Timer? _dwell, _holdSelect;
  LogicalKeyboardKey? _pressedSelect;
  bool _hover = false, _focus = false, _preview = false, _dialog = false;
  bool _dismissed = false;

  // A shell branch can still be current in its own navigator while Details
  // is covering the shell in the root navigator.
  bool get _routeVisible {
    ModalRoute<dynamic>? route = ModalRoute.of(context);
    while (route != null) {
      if (!route.isCurrent) return false;
      final parent = route.navigator;
      route = parent == null ? null : ModalRoute.of(parent.context);
    }
    return true;
  }

  void _activate() {
    _dismissed = true;
    _hide();
    widget.onSelect?.call();
  }

  KeyEventResult _onSelectKey(FocusNode node, KeyEvent event) {
    if (!widget.tvNavigation ||
        widget.onSelect == null ||
        !_selectKeys.contains(event.logicalKey)) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && !event.synthesized) {
      _pressedSelect = event.logicalKey;
      _holdSelect?.cancel();
      _holdSelect = Timer(const Duration(milliseconds: 550), () {
        _holdSelect = null;
        if (mounted && node.hasFocus && _routeVisible) {
          unawaited(_openPreview());
        }
      });
    } else if (event is KeyUpEvent && event.logicalKey == _pressedSelect) {
      _pressedSelect = null;
      final tap = _holdSelect?.isActive == true && !event.synthesized;
      _holdSelect?.cancel();
      _holdSelect = null;
      if (tap && _routeVisible) _activate();
    }
    return KeyEventResult.handled;
  }

  static const _selectKeys = [
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
  ];

  void _interaction({bool? hover, bool? focus}) {
    if (hover != null) _hover = hover;
    if (focus != null) _focus = focus;
    if (!_hover && !_focus) {
      _dismissed = false;
      _hide();
    } else if (!_preview && !_dialog && !_dismissed) {
      _dwell ??= Timer(const Duration(milliseconds: 420), () {
        _dwell = null;
        if (!mounted || !_routeVisible) return;
        _activePreview?._hide();
        _activePreview = this;
        FocusManager.instance.addEarlyKeyEventHandler(_dismissKey);
        setState(() => _preview = true);
      });
    }
  }

  KeyEventResult _dismissKey(KeyEvent event) {
    if (event is! KeyDownEvent ||
        !_routeVisible ||
        (event.logicalKey != LogicalKeyboardKey.escape &&
            event.logicalKey != LogicalKeyboardKey.goBack &&
            event.logicalKey != LogicalKeyboardKey.browserBack &&
            !(widget.tvNavigation &&
                event.logicalKey == LogicalKeyboardKey.colorF0Red))) {
      return KeyEventResult.ignored;
    }
    PosterCard.dismissVisiblePreview();
    return KeyEventResult.handled;
  }

  void _hide() {
    _dwell?.cancel();
    _dwell = null;
    if (_preview) {
      if (identical(_activePreview, this)) _activePreview = null;
      FocusManager.instance.removeEarlyKeyEventHandler(_dismissKey);
      setState(() => _preview = false);
    }
  }

  Future<void> _openPreview() async {
    if (_dialog) return;
    _dialog = true;
    _dismissed = true;
    _hide();
    final dialog = CatalogPreviewDialog(
      item: widget.item,
      canSelect: widget.onSelect != null,
      hasDetails: widget.onDetails != null,
      canRemove: widget.onRemove != null,
    );
    final action = await showDialog<CardAction>(
      context: context,
      builder: (_) => dialog,
    );
    if (!mounted) return;
    _dialog = false;
    switch (action) {
      case CardAction.select:
        _activate();
      case CardAction.details:
        widget.onDetails?.call();
      case CardAction.remove:
        widget.onRemove?.call();
      case null:
        break;
    }
  }

  @override
  void dispose() {
    _dwell?.cancel();
    _holdSelect?.cancel();
    if (identical(_activePreview, this)) _activePreview = null;
    if (_preview) FocusManager.instance.removeEarlyKeyEventHandler(_dismissKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final active = _preview;
    final artwork = MediaArtwork(
      title: item.title,
      kind: ArtworkKind.forMedia(item.type),
      hasCaption: true,
      url: item.imageUrl,
      fallbackArtwork: item is HomePick && item.work.imdbId != null
          ? Consumer(
              builder: (_, ref, _) {
                final url = ref
                    .watch(
                      actorTitlePosterProvider((
                        item.work.kind,
                        item.work.imdbId!,
                      )),
                    )
                    .value;
                return MediaArtwork(
                  title: item.title,
                  kind: ArtworkKind.forMedia(item.type),
                  hasCaption: true,
                  url: url,
                  icon: mediaIcon(item.type),
                  width: widget.width,
                  radius: 0,
                  cacheWidth: (widget.width * 2).round(),
                );
              },
            )
          : null,
      radius: 0,
      width: widget.width,
      icon: mediaIcon(item.type),
      logo: item.type == MediaType.live,
      cacheWidth: (widget.width * 2).round(),
    );
    final card = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyI): _openPreview,
        const SingleActivator(LogicalKeyboardKey.contextMenu): _openPreview,
        const SingleActivator(LogicalKeyboardKey.f10, shift: true):
            _openPreview,
      },
      child: Focusable(
        onSelect: widget.onSelect == null ? null : _activate,
        onLongPress: widget.onRemove ?? _openPreview,
        onFocused: (v) => _interaction(focus: v),
        onHovered: (v) => _interaction(hover: v),
        focusScale: 1.028,
        ensureVisible: !widget.tvNavigation,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: widget.width,
          height: widget.width * (widget.wide ? 9 / 16 : 1.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Semantics(
                button: widget.onSelect != null,
                label: [
                  if (widget.rank != null) 'Rank ${widget.rank}',
                  item.title,
                  if (item.badge != null && item.badge != item.title)
                    item.badge!,
                  item.actionLabel,
                ].join(', '),
                hint: widget.tvNavigation ? 'Hold OK for preview' : null,
                excludeSemantics: true,
                onTap: widget.onSelect == null ? null : _activate,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (item.continueWatching) ...[
                      ColoredBox(
                        color: Color.lerp(AppColors.surface, item.color, .16)!,
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FractionallySizedBox(
                          widthFactor: .49,
                          heightFactor: 1,
                          child: artwork,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: AlignmentDirectional.centerStart,
                            end: AlignmentDirectional.centerEnd,
                            stops: const [0, .51, .80, 1],
                            colors: [
                              Color.lerp(AppColors.surface, item.color, .16)!,
                              Color.lerp(AppColors.surface, item.color, .16)!,
                              Colors.transparent,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ] else
                      artwork,
                    AnimatedContainer(
                      duration: reduced
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0, .35, .72, 1],
                          colors: active
                              ? const [
                                  Color(0x18000000),
                                  Color(0x800A0A10),
                                  Color(0xEF0C0C12),
                                  Color(0xFF0C0C12),
                                ]
                              : const [
                                  Colors.transparent,
                                  Colors.transparent,
                                  Color(0x8205050A),
                                  Color(0xF50A0A0F),
                                ],
                        ),
                      ),
                    ),
                    if (widget.rank case final rank?)
                      _ChartCaption(
                        item: item,
                        rank: rank,
                        width: widget.width,
                        preview: active,
                      )
                    else
                      _CardCaption(
                        item: item,
                        preview: active,
                        wide: widget.wide,
                        tvResume: widget.tvNavigation && item.continueWatching,
                      ),
                    if (item.progress case final p?)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(
                          value: p.clamp(0, 1),
                          minHeight: 3,
                          color: AppColors.primary,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 1,
                end: 1,
                child: ExcludeFocus(
                  excluding: widget.tvNavigation,
                  child: IconButton(
                    tooltip: 'Preview ${item.title}',
                    onPressed: _openPreview,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xC8111117),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.more_horiz_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return widget.tvNavigation
        ? Focus(canRequestFocus: false, onKeyEvent: _onSelectKey, child: card)
        : card;
  }
}

class _ChartCaption extends StatelessWidget {
  const _ChartCaption({
    required this.item,
    required this.rank,
    required this.width,
    required this.preview,
  });
  final MediaItem item;
  final int rank;
  final double width;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final number = rank.toString().padLeft(2, '0');
    final numberSize = (width * .33).clamp(54.0, 112.0);
    final style = TextStyle(
      fontSize: numberSize,
      height: 1,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      letterSpacing: -numberSize * .08,
    );
    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: Padding(
        padding: EdgeInsets.fromLTRB(width < 240 ? 12 : 18, 8, 14, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Stack(
                children: [
                  Text(
                    number,
                    textScaler: TextScaler.noScaling,
                    style: style.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2.4
                        ..color = Colors.white,
                    ),
                  ),
                  Text(
                    number,
                    textScaler: TextScaler.noScaling,
                    style: style.copyWith(color: const Color(0xF521212A)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              item.title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: (width * .083).clamp(19, 28),
                height: 1.08,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              preview
                  ? 'View details'
                  : [
                      item.kindLabel,
                      if (item.subtitle.isNotEmpty) item.subtitle,
                    ].join('  ·  '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE2E1E6),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardCaption extends ConsumerWidget {
  const _CardCaption({
    required this.item,
    required this.preview,
    required this.wide,
    required this.tvResume,
  });
  final MediaItem item;
  final bool preview, wide, tvResume;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = preview ? previewFor(ref, item) : emptyCardPreview;
    final badge = item.badge != item.title ? item.badge : null;
    final subtitle = item.subtitle.split(' — ').last.trim();
    final summary =
        (subtitle.isNotEmpty && subtitle != data.metadata && subtitle != badge)
        ? subtitle
        : data.summary;
    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxWidth < 145;
        final inset = tvResume
            ? (c.maxWidth * .05).clamp(12.0, 20.0)
            : compact
            ? 7.0
            : 11.0;
        final height = c.maxHeight / MediaQuery.textScalerOf(context).scale(1);
        final titleCover =
            !wide && !preview && (item.imageUrl?.trim().isEmpty ?? true);
        final showMeta = preview && height > 110 && !item.continueWatching;
        final showSummary =
            (preview || item.continueWatching) &&
            summary?.isNotEmpty == true &&
            height > (item.continueWatching ? 92 : 150);
        final extraPlot =
            preview &&
            item.continueWatching &&
            height > 125 &&
            data.summary?.isNotEmpty == true &&
            data.summary != summary;
        final meta = [
          item.kindLabel,
          data.metadata,
        ].where((s) => s.isNotEmpty).join(' · ');
        return Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            inset,
            2,
            item.continueWatching ? c.maxWidth * (preview ? .20 : .36) : inset,
            inset,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null && badge.isNotEmpty && height > 65)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    badge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFC4C7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (showMeta && meta.isNotEmpty)
                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Flexible(
                flex: 2,
                child: Text(
                  item.title,
                  maxLines: wide && height < 100 ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: tvResume
                        ? (c.maxWidth * .072).clamp(18.0, 27.0)
                        : titleCover
                        ? (c.maxWidth * .13).clamp(17.0, 34.0)
                        : compact
                        ? 13
                        : 16,
                    height: titleCover || tvResume ? 1.09 : 1.26,
                    fontWeight: titleCover ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
              if (showSummary)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE1E1E7),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              if (extraPlot)
                Flexible(
                  child: Text(
                    data.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                ),
              if ((preview || item.continueWatching) && height > 100)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        item.continueWatching || item.type == MediaType.live
                            ? Icons.play_arrow_rounded
                            : Icons.arrow_forward_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          item.actionLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
