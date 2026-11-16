import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../responsive/form_factor.dart';

/// Tracks how the user is currently driving the app: d-pad/arrow keys or
/// pointer/touch. Autofocus is only wanted for d-pad navigation — a visible
/// focus ring appearing on its own is noise for mouse and touch users.
///
/// TV builds start in d-pad mode; everything else starts pointer-first. The
/// first arrow/select key press flips to d-pad mode, the next pointer-down
/// flips back, so a desktop user who picks up a remote (or vice versa) gets
/// the right behavior without restarting.
abstract final class InputModality {
  static final ValueNotifier<bool> dpad = ValueNotifier(kTvBuild);

  static bool get usesDpad => dpad.value;

  static final _dpadKeys = <LogicalKeyboardKey>{
    LogicalKeyboardKey.arrowUp,
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.arrowLeft,
    LogicalKeyboardKey.arrowRight,
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.gameButtonA,
  };

  /// Registers the key handler once at startup. Never consumes events.
  static void attach() {
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  static bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent && _dpadKeys.contains(event.logicalKey)) {
      dpad.value = true;
    }
    return false;
  }

  static void notePointer() {
    if (dpad.value) dpad.value = false;
  }
}
