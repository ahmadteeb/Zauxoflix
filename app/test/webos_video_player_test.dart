import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:zauxoflix/features/player/webos_video_player.dart';

class _VisiblePlayer extends WebOsVideoPlayer {
  int checks = 0;
  @override
  bool isReady(int textureId) {
    checks++;
    return true;
  }

  @override
  Future<void> viewRect(
    int texId,
    double x,
    double y,
    double w,
    double h,
  ) async {}
}

void main() {
  testWidgets('seek frame acknowledgment is matched to the requested time', (
    tester,
  ) async {
    const id = 5;
    const channel = 'flutter.io/videoPlayer/videoEvents$id';
    const nativeSeek = 'dev.flutter.pigeon.WebOsVideoPlayerApi.seekTo';
    const codec = StandardMethodCodec();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMessageHandler(
      nativeSeek,
      (_) async => const StandardMessageCodec().encodeMessage([null]),
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel(channel),
      (call) async => null,
    );
    final player = WebOsVideoPlayer();
    final events = player.videoEventsFor(id).listen((_) {});
    addTearDown(() async {
      await events.cancel();
      messenger.setMockMethodCallHandler(const MethodChannel(channel), null);
      messenger.setMockMessageHandler(nativeSeek, null);
    });
    await tester.pump();
    Future<void> signal(String event, int position) =>
        messenger.handlePlatformMessage(
          channel,
          codec.encodeSuccessEnvelope({'event': event, 'position': position}),
          (data) {},
        );

    var decoded = false;
    final preview = player
        .seekAndWaitForFrame(
          () => player.seekTo(id, const Duration(seconds: 23)),
        )
        .then((_) => decoded = true);
    await signal('seekCompleted', 13000);
    await tester.pump();
    expect(decoded, isFalse);
    await signal('seekCompleted', 23000);
    await preview;
    expect(decoded, isTrue);

    final failure = expectLater(
      player.seekAndWaitForFrame(
        () => player.seekTo(id, const Duration(seconds: 7)),
      ),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'seek_unavailable',
        ),
      ),
    );
    await signal('seekFailed', 7000);
    await failure;
  });

  testWidgets(
    'retired LG video stops checking geometry and cancels its moving timer',
    (tester) async {
      final player = _VisiblePlayer();
      await tester.pumpWidget(MaterialApp(home: player.buildView(1)));
      expect(player.checks, greaterThan(0));
      await tester.pumpWidget(const SizedBox());
      final afterRemoval = player.checks;
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 110));
      expect(player.checks, afterRemoval);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a late exported window is released without opening a stale stream',
    (tester) async {
      const window = MethodChannel('webos/exported_windows');
      final reply = Completer<String>();
      final disposed = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(window, (
        call,
      ) async {
        if (call.method == 'create') return reply.future;
        disposed.add(call.arguments);
        return null;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          window,
          null,
        ),
      );
      final player = WebOsVideoPlayer();
      final opening = player.create(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.test/stale',
        ),
      );
      await tester.pump(const Duration(seconds: 13));
      final id = (await opening)!;
      await expectLater(
        player.videoEventsFor(id),
        emitsError(isA<PlatformException>()),
      );
      await player.dispose(id);
      reply.complete('late');
      await tester.pump();
      expect(disposed, [
        {'windowId': 'late'},
      ]);
    },
  );

  testWidgets(
    'native creation failure produces a disposable controller error',
    (tester) async {
      final messenger = tester.binding.defaultBinaryMessenger;
      const window = MethodChannel('webos/exported_windows');
      messenger.setMockMethodCallHandler(
        window,
        (_) async => throw PlatformException(code: 'unavailable'),
      );
      addTearDown(() => messenger.setMockMethodCallHandler(window, null));
      final player = WebOsVideoPlayer();
      final id = await player.create(
        DataSource(
          sourceType: DataSourceType.network,
          uri: 'https://example.test/live',
        ),
      );
      await expectLater(
        player.videoEventsFor(id!),
        emitsError(isA<PlatformException>()),
      );
      await player.dispose(id);
    },
  );
}
