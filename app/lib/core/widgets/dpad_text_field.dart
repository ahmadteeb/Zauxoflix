import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../input/input_modality.dart';
import '../theme/app_theme.dart';

/// TV-friendly wrapper for text fields. With d-pad input, focus traversal
/// lands on the wrapper (highlight ring, no keyboard); pressing OK/Select
/// moves focus into the field and opens the keyboard, and back or the
/// vertical arrows leave edit mode again. With pointer/touch input the
/// wrapper is transparent: taps and Tab reach the field directly.
class DpadTextField extends StatefulWidget {
  const DpadTextField({
    super.key,
    required this.builder,
    this.autofocus = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(10)),
  });

  /// Builds the actual [TextField]/[TextFormField]; must attach [fieldNode]
  /// as its focusNode so the wrapper can hand focus over on OK.
  final Widget Function(BuildContext context, FocusNode fieldNode) builder;

  /// With d-pad input this focuses the wrapper (landing spot, no keyboard);
  /// with pointer input it focuses the field itself like a plain autofocus.
  final bool autofocus;
  final BorderRadius borderRadius;

  @override
  State<DpadTextField> createState() => _DpadTextFieldState();
}

class _DpadTextFieldState extends State<DpadTextField> {
  final _outer = FocusNode(debugLabel: 'DpadTextField.outer');
  final _field = FocusNode(debugLabel: 'DpadTextField.field');

  @override
  void initState() {
    super.initState();
    _outer.addListener(_onFocusChanged);
    _field.addListener(_onFocusChanged);
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        (InputModality.usesDpad ? _outer : _field).requestFocus();
      });
    }
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _outer.dispose();
    _field.dispose();
    super.dispose();
  }

  static final _selectKeys = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.numpadEnter,
    LogicalKeyboardKey.gameButtonA,
  };

  static final _exitKeys = {
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.goBack,
  };

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (!InputModality.usesDpad) return KeyEventResult.ignored;
    if (_field.hasFocus) {
      // Editing: back or vertical arrows return to the traversal layer;
      // everything else (including Enter → onSubmitted) goes to the field.
      if (_exitKeys.contains(event.logicalKey)) {
        _outer.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (_selectKeys.contains(event.logicalKey)) {
      _field.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: InputModality.dpad,
      builder: (context, dpad, _) {
        // D-pad traversal stops on the wrapper; pointer/desktop Tab skips it
        // and reaches the field like a plain TextField.
        _outer.skipTraversal = !dpad;
        _field.skipTraversal = dpad;
        final ringVisible = dpad && _outer.hasFocus && !_field.hasFocus;
        return Focus(
          focusNode: _outer,
          onKeyEvent: _onKeyEvent,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              border: Border.all(
                color: ringVisible ? AppColors.focusRing : Colors.transparent,
                width: 2,
              ),
            ),
            child: widget.builder(context, _field),
          ),
        );
      },
    );
  }
}
