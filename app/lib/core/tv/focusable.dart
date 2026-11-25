import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wraps any widget to make it D-pad/keyboard focusable with a Netflix-style
/// scale + white ring highlight. Also handles tap for touch/mouse.
class Focusable extends StatefulWidget {
  const Focusable({
    super.key,
    required this.child,
    this.onSelect,
    this.onLongPress,
    this.onFocused,
    this.onHovered,
    this.focusScale = 1.08,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.autofocus = false,
    this.ensureVisible = true,
  });

  final Widget child;
  final VoidCallback? onSelect;

  /// Long-press (touch/mouse) or right-click, e.g. to remove a rail item.
  final VoidCallback? onLongPress;
  final ValueChanged<bool>? onFocused, onHovered;
  final double focusScale;
  final BorderRadius borderRadius;
  final bool autofocus;
  final bool ensureVisible;

  @override
  State<Focusable> createState() => _FocusableState();
}

class _FocusableState extends State<Focusable> {
  bool _focused = false;
  bool _hovered = false;

  void _handleFocusHighlight(bool focused) {
    setState(() => _focused = focused);
    widget.onFocused?.call(focused);
    if (focused && widget.ensureVisible) {
      // Post-frame so scroll metrics are settled before we scroll.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          alignment: 0.5,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hover gets the same scale lift as focus but no ring — the ring is a
    // D-pad affordance, while mouse users already know where the pointer is.
    final lifted = _focused || _hovered;
    final control = FocusableActionDetector(
      autofocus: widget.autofocus,
      mouseCursor: widget.onSelect != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onShowFocusHighlight: _handleFocusHighlight,
      onShowHoverHighlight: (hovered) => setState(() => _hovered = hovered),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onSelect?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onSelect,
        onLongPress: widget.onLongPress,
        onSecondaryTap: widget.onLongPress,
        child: AnimatedScale(
          scale: lifted && !MediaQuery.disableAnimationsOf(context)
              ? widget.focusScale
              : 1.0,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: _focused
                    ? AppColors.focusRing
                    : _hovered
                    ? Colors.white24
                    : Colors.transparent,
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.all(
                Radius.circular(
                  widget.borderRadius.topLeft.x - 3 > 0
                      ? widget.borderRadius.topLeft.x - 3
                      : 0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
    if (widget.onHovered == null) return control;
    return MouseRegion(
      onEnter: (_) => widget.onHovered!(true),
      onExit: (_) => widget.onHovered!(false),
      child: control,
    );
  }
}
