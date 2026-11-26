import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/widgets/close_database_on_exit.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';

class _SlowDatabase extends AppDatabase {
  _SlowDatabase(this.events) : super.forTesting(NativeDatabase.memory());

  final List<String> events;
  final closed = Completer<void>();

  @override
  Future<void> close() async {
    events.add('closing database');
    await closed.future;
    events.add('database closed');
  }
}

void main() {
  testWidgets('the window is destroyed only after the database closes', (
    tester,
  ) async {
    const channel = MethodChannel('window_manager');
    final events = <String>[];
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      events.add(call.method);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    Future<void> pressClose() => messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('onEvent', {'eventName': 'close'}),
      ),
      (_) {},
    );
    final db = _SlowDatabase(events);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: CloseDatabaseOnExit(
          child: Consumer(
            builder: (_, ref, _) {
              ref.watch(databaseProvider);
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    await pressClose();
    await pressClose();
    await tester.pump();
    expect(events, ['setPreventClose', 'closing database']);

    db.closed.complete();
    await tester.pump();

    expect(events, [
      'setPreventClose',
      'closing database',
      'database closed',
      'destroy',
    ]);
  });
}
