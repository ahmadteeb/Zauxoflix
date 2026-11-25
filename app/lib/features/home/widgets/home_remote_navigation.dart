import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../shell/top_nav_bar.dart';
import 'poster_card.dart';

/// Marks a logical row on Home. A rail can show just a few of its cards at a
/// time. Its focus history belongs to that rail, independently of its neighbors.
class HomeFocusRow extends StatefulWidget {
  const HomeFocusRow({
    super.key,
    required this.child,
    this.railGutter,
    this.featured = false,
  });
  final bool featured;
  final Widget child;
  final double? railGutter;

  @override
  State<HomeFocusRow> createState() => _HomeFocusRowState();
}

class _HomeFocusRowState extends State<HomeFocusRow> {
  final node = _RowNode();
  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<HomeRemoteNavigation>() == null) {
      return widget.child;
    }
    node.featured = widget.featured;
    node.gutter = widget.railGutter;
    node.rowKey = widget.key;
    return Focus(focusNode: node, canRequestFocus: false, child: widget.child);
  }
}

class _RowNode extends FocusNode {
  bool featured = false;
  Key? rowKey;
  FocusNode? remembered;
  double? gutter;

  List<FocusNode> get controls =>
      traversalDescendants
          .where(
            (n) =>
                n.traversalChildren.isEmpty &&
                n.context?.findRenderObject()?.attached == true,
          )
          .toList()
        ..sort((a, b) {
          final x = a.rect.center.dx.compareTo(b.rect.center.dx);
          return x == 0 ? a.rect.top.compareTo(b.rect.top) : x;
        });
}

class _HomeNode extends FocusNode {
  _HomeNode(this.enter);
  final VoidCallback enter;
}

class HomeRemoteNavigation extends StatefulWidget {
  /// Enter the featured row even when the list was left scrolled to a later rail.
  static bool enterFromTop(FocusNode scope) {
    final home = scope.descendants.whereType<_HomeNode>().firstOrNull;
    if (home == null) return false;
    home.enter();
    return true;
  }

  const HomeRemoteNavigation({super.key, required this.child});
  final Widget child;

  @override
  State<HomeRemoteNavigation> createState() => _HomeRemoteNavigationState();
}

class _HomeRemoteNavigationState extends State<HomeRemoteNavigation> {
  // Slivers may dispose an offscreen row. Restore its offset and title by
  // identity when it comes back, without keeping an entire catalog in memory.
  final _scrollPositions = PageStorageBucket();
  final _lastCards = <Key, Key>{};

  late final _home = _HomeNode(_enterFromTop);

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  void _enterFromTop() {
    final rows = _home.descendants.whereType<_RowNode>();
    final context = rows.firstOrNull?.context;
    if (context == null) return;
    final scroll = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (scroll != null) scroll.jumpTo(scroll.minScrollExtent);
    // Jumping from a later rail may need to mount the hero sliver again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || ModalRoute.of(this.context)?.isCurrent == false) return;
      final hero = _home.descendants
          .whereType<_RowNode>()
          .where((r) => r.featured)
          .firstOrNull;
      final options = hero?.controls;
      if (hero == null || options == null || options.isEmpty) return;
      _move(hero, options.first);
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Key? _cardKey(FocusNode control) =>
      control.context?.findAncestorWidgetOfExactType<PosterCard>()?.key;

  void _remember(_RowNode row, FocusNode control) {
    row.remembered = control;
    final card = _cardKey(control);
    if (row.rowKey case final key? when card != null) _lastCards[key] = card;
  }

  void _reveal(
    ScrollPosition p,
    RenderObject target,
    double before,
    double after, {
    bool animate = false,
  }) {
    final viewport = RenderAbstractViewport.of(target);
    final start = viewport.getOffsetToReveal(target, 0).offset - before;
    final end = viewport.getOffsetToReveal(target, 1).offset + after;
    final offset =
        (end > start || p.pixels > start
                ? start
                : p.pixels < end
                ? end
                : p.pixels)
            .clamp(p.minScrollExtent, p.maxScrollExtent)
            .toDouble();
    if ((p.pixels - offset).abs() <= 1) {
      if (p.isScrollingNotifier.value) p.jumpTo(p.pixels);
      return;
    }
    if (animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        !MediaQuery.accessibleNavigationOf(context)) {
      p.animateTo(
        offset,
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOutCubic,
      );
    } else {
      p.jumpTo(offset);
    }
  }

  void _move(_RowNode row, FocusNode control) {
    _remember(row, control);
    control.requestFocus();
    final ctx = control.context!;
    final gutter = row.gutter;
    final horizontal = Scrollable.maybeOf(ctx, axis: Axis.horizontal);
    if (gutter != null && horizontal != null) {
      _reveal(horizontal.position, ctx.findRenderObject()!, gutter, gutter);
    }
    final rowContext = row.context!;
    final vertical = Scrollable.maybeOf(rowContext, axis: Axis.vertical);
    if (vertical != null) {
      if (row.featured) {
        vertical.position.jumpTo(vertical.position.minScrollExtent);
        return;
      }
      _reveal(
        vertical.position,
        rowContext.findRenderObject()!,
        kTopNavHeight + 8,
        12,
        animate: true,
      );
    }
  }

  KeyEventResult _key(FocusNode root, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final horizontal =
        key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight;
    final down = key == LogicalKeyboardKey.arrowDown;
    if (!horizontal && !down && key != LogicalKeyboardKey.arrowUp) {
      return KeyEventResult.ignored;
    }
    final current = FocusManager.instance.primaryFocus;
    final row = current?.ancestors.whereType<_RowNode>().firstOrNull;
    if (row == null || current == null) return KeyEventResult.ignored;
    final controls = row.controls;
    final index = controls.indexOf(current);
    if (index < 0) return KeyEventResult.ignored;
    _remember(row, current);
    if (horizontal) {
      final next = index + (key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      if (next >= 0 && next < controls.length) _move(row, controls[next]);
      return KeyEventResult.handled;
    }

    // The hero and chart filters can wrap. Keep controls stacked in the same
    // column reachable before moving into another section.
    if (row.gutter == null) {
      final from = current.rect;
      final column =
          controls.where((n) {
            final r = n.rect;
            return r.left < from.right &&
                r.right > from.left &&
                (down ? r.top >= from.bottom - 1 : r.bottom <= from.top + 1);
          }).toList()..sort(
            (a, b) => (a.rect.center - from.center).distanceSquared.compareTo(
              (b.rect.center - from.center).distanceSquared,
            ),
          );
      if (column.isNotEmpty) {
        _move(row, column.first);
        return KeyEventResult.handled;
      }
    }
    final rows =
        root.descendants
            .whereType<_RowNode>()
            .where((r) => r.controls.isNotEmpty)
            .toList()
          ..sort((a, b) => a.rect.top.compareTo(b.rect.top));
    final next = rows.indexOf(row) + (down ? 1 : -1);
    if (next >= 0 && next < rows.length) {
      final target = rows[next];
      final options = target.controls;
      final saved = _lastCards[target.rowKey];
      final remembered = saved == null
          ? target.remembered
          : options.where((n) => _cardKey(n) == saved).firstOrNull;
      _move(
        target,
        remembered != null && options.contains(remembered)
            ? remembered
            : Directionality.of(target.context!) == TextDirection.rtl
            ? options.last
            : options.first,
      );
    } else if (!down) {
      final context = root.context!;
      if (Actions.maybeFind<FocusTopBarIntent>(context) == null) {
        return KeyEventResult.ignored;
      }
      Actions.invoke(context, const FocusTopBarIntent());
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => PageStorage(
    bucket: _scrollPositions,
    child: Focus(
      focusNode: _home,
      canRequestFocus: false,
      onKeyEvent: _key,
      child: widget.child,
    ),
  );
}
