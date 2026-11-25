import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/features/player/seek_filmstrip.dart';
import 'package:zauxoflix/features/player/seek_frames.dart';

class _Reader implements SeekFrameReader {
  final _response = Completer<List<DecodedSeekFrame?>>();
  void Function(List<DecodedSeekFrame?>)? sendFrames;

  @override
  Future<List<DecodedSeekFrame?>> read(
    Duration time, {
    void Function(List<DecodedSeekFrame?>)? onFrames,
  }) {
    sendFrames = onFrames;
    return _response.future;
  }

  @override
  void dispose() {}
}

DecodedSeekFrame _frame(Duration time) => DecodedSeekFrame(
  time,
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACXBIWXMAAAsTAAALEwEAmpwY'
    'AAAADUlEQVQImWNgYGD4DwABBAEAX+XDSgAAAABJRU5ErkJggg==',
  ),
);

void main() {
  testWidgets('the independent reader shows frames before it finishes', (
    tester,
  ) async {
    const target = Duration(seconds: 28);
    final reader = _Reader();
    final resolved = <Duration>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SeekFilmstrip(
            target: target,
            reader: reader,
            onResolved: resolved.add,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(Image), findsNothing);

    reader.sendFrames!([
      _frame(target - const Duration(seconds: 1)),
      null,
      null,
    ]);
    await tester.pump();
    expect(find.byKey(const ValueKey('seek-frame-0')), findsOneWidget);
    expect(resolved, isEmpty);

    reader.sendFrames!([null, _frame(target), null]);
    await tester.pump();
    expect(find.byKey(const ValueKey('seek-frame-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('seek-frame-1')), findsOneWidget);
    expect(resolved, [target]);
    expect(reader._response.isCompleted, isFalse);
  });

  testWidgets('committed playback fills the strip while its extra read waits', (
    tester,
  ) async {
    const selected = Duration(milliseconds: 13240);
    final reader = _Reader();
    final resolved = <Duration>[];
    void Function(int, DecodedSeekFrame)? render;
    var captures = 0;
    final complete = Completer<void>();

    Widget view(Duration? committed) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 410,
          child: SeekFilmstrip(
            target: selected,
            reader: reader,
            onResolved: resolved.add,
            playbackTarget: committed,
            playbackFrames: (target, current, onFrame) {
              expect(target, selected);
              captures++;
              render = onFrame;
              return complete.future;
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(view(null));
    await tester.pump(const Duration(milliseconds: 120));
    expect(captures, 0);
    expect(find.byKey(const ValueKey('seek-frame-1')), findsNothing);

    await tester.pumpWidget(view(selected));
    expect(captures, 1);
    render!(1, _frame(selected));
    await tester.pump();
    expect(find.byKey(const ValueKey('seek-frame-1')), findsOneWidget);
    expect(resolved, [selected]);

    // A failed extra connection must never erase the frame we already saw.
    reader._response.complete(const []);
    await tester.pump();
    expect(find.byKey(const ValueKey('seek-frame-1')), findsOneWidget);
    expect(find.text('Frame preview unavailable'), findsNothing);

    render!(2, _frame(selected + const Duration(seconds: 1)));
    complete.complete();
    await tester.pump();
    expect(find.byKey(const ValueKey('seek-frame-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('seek-frame-0')), findsNothing);
  });

  testWidgets('a stale active-player picture cannot fill a newer seek', (
    tester,
  ) async {
    final reader = _Reader();
    const old = Duration(seconds: 20);
    const next = Duration(seconds: 70);
    final finished = Completer<void>();
    final resolved = <Duration>[];
    final snapshots = <void Function(int, DecodedSeekFrame)>[];

    Widget view(Duration time) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 410,
          child: SeekFilmstrip(
            target: time,
            playbackTarget: time,
            reader: reader,
            onResolved: resolved.add,
            playbackFrames: (target, current, onFrame) {
              snapshots.add(onFrame);
              return target == old ? finished.future : Future.value();
            },
          ),
        ),
      ),
    );

    await tester.pumpWidget(view(old));
    await tester.pumpWidget(view(next));
    snapshots.first(1, _frame(old));
    finished.complete();
    await tester.pump();
    expect(snapshots, hasLength(2));
    expect(find.byKey(const ValueKey('seek-frame-1')), findsNothing);
    expect(resolved, isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}
