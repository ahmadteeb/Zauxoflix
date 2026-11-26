import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import '../../data/providers.dart';

/// Holds the desktop window open until the database has closed.
///
/// Otherwise drift's background isolate closes SQLite while the Dart VM is
/// shutting down, and SQLite's callbacks into Dart abort the process.
class CloseDatabaseOnExit extends ConsumerStatefulWidget {
  const CloseDatabaseOnExit({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CloseDatabaseOnExit> createState() =>
      _CloseDatabaseOnExitState();
}

class _CloseDatabaseOnExitState extends ConsumerState<CloseDatabaseOnExit>
    with WindowListener {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(windowManager.setPreventClose(true));
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() => unawaited(_close());

  Future<void> _close() async {
    // destroy() reports a second close event on Linux.
    if (_closing) return;
    _closing = true;
    try {
      if (ref.exists(databaseProvider)) {
        // The window must still close if the database never answers.
        await ref
            .read(databaseProvider)
            .close()
            .timeout(const Duration(seconds: 3));
      }
    } catch (error) {
      debugPrint('Database did not close cleanly: ${error.runtimeType}');
    } finally {
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
