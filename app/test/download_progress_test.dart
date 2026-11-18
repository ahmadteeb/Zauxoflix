import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/downloads/download_manager.dart';
import 'package:zauxoflix/features/downloads/download_progress_details.dart';

void main() {
  const progress = DownloadProgress(
    DownloadPhase.downloading,
    receivedBytes: 1024 * 1024,
    totalBytes: 2 * 1024 * 1024,
    bytesPerSecond: 512 * 1024,
    elapsed: Duration(seconds: 2),
  );

  test('known size reports percentage, bytes, speed, elapsed time and ETA', () {
    expect(progress.value, 0.5);
    expect(progress.remaining, const Duration(seconds: 2));
    expect(
      downloadProgressText(progress),
      '50% · 1.0 MB / 2.0 MB\n512.0 KB/s · 2s elapsed · 2s left',
    );
  });

  test(
    'unknown size reports received bytes without a false percentage or ETA',
    () {
      const unknown = DownloadProgress(
        DownloadPhase.downloading,
        receivedBytes: 1024,
        bytesPerSecond: 512,
      );
      expect(unknown.remaining, isNull);
      final text = downloadProgressText(unknown);
      expect(text, contains('1.0 KB downloaded · Size unknown'));
      expect(text, contains('512 B/s'));
      expect(text, isNot(contains('%')));
      expect(text, isNot(contains('left')));
    },
  );

  test('waiting for speed has no ETA and completed progress is bounded', () {
    const waiting = DownloadProgress(
      DownloadPhase.downloading,
      totalBytes: 100,
    );
    expect(waiting.remaining, isNull);
    const complete = DownloadProgress(
      DownloadPhase.downloading,
      receivedBytes: 101,
      totalBytes: 100,
      bytesPerSecond: 10,
    );
    expect(complete.value, 1);
    expect(complete.remaining, Duration.zero);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('download details fit a narrow row at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: ListTile(
                leading: const SizedBox(width: 48, child: Icon(Icons.movie)),
                title: const Text('A movie download'),
                subtitle: const DownloadProgressDetails(progress: progress),
                trailing: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.close),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.textContaining('50%'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        0.5,
      );
    });
  }

  testWidgets('unknown download size uses an indeterminate bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DownloadProgressDetails(
            progress: DownloadProgress(
              DownloadPhase.downloading,
              receivedBytes: 1024,
            ),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );
    expect(find.textContaining('Size unknown'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
