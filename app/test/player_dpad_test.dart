import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:zauxoflix/features/player/player_volume.dart';
// Exercise focus without a native decoder or network stream.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/features/player/player_screen.dart';
import 'package:zauxoflix/features/remote/remote_playback.dart';

class _VideoPlatform extends VideoPlayerPlatform {
  @override
  Future<void> init() async {}
  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async => 1;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) => const Stream.empty();
  @override
  Future<void> dispose(int playerId) async {}
}

class _RemotePlayback extends RemotePlaybackController {
  @override
  void build() {}
  @override
  void attachPlayer(RemotePlayerHandle handle) {}
  @override
  void detachPlayer(RemotePlayerHandle handle) {}
  @override
  void playerChanged() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final original = VideoPlayerPlatform.instance;
    VideoPlayerPlatform.instance = _VideoPlatform();
    addTearDown(() => VideoPlayerPlatform.instance = original);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler(
          'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
          (_) async => const StandardMessageCodec().encodeMessage([null]),
        );
  });

  Future<void> openPlayer(WidgetTester tester, {PlayerArgs? args}) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [remotePlaybackProvider.overrideWith(_RemotePlayback.new)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: PlayerScreen(
            args:
                args ??
                PlayerArgs.single(
                  url: 'https://example.test/video.mp4',
                  title: 'Test video',
                ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> closePlayer(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets('player gain survives channel changes', (tester) async {
    await openPlayer(
      tester,
      args: PlayerArgs(
        items: const [
          PlayerItem(
            url: 'https://example.test/one.ts',
            title: 'One',
            live: true,
          ),
          PlayerItem(
            url: 'https://example.test/two.ts',
            title: 'Two',
            live: true,
          ),
        ],
      ),
    );
    VideoPlayerController controller() =>
        tester
                .widgetList<ValueListenableBuilder<VideoPlayerValue>>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is ValueListenableBuilder<VideoPlayerValue>,
                  ),
                )
                .first
                .valueListenable
            as VideoPlayerController;

    await tester.tap(find.byTooltip('Player volume'));
    await tester.pump();
    tester.widget<Slider>(find.byType(Slider)).onChanged!(0.35);
    await tester.pump();
    expect(controller().value.volume, closeTo(0.35, 0.001));
    expect(find.text('35%'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(controller().value.volume, closeTo(0.4, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller().value.volume, closeTo(0.35, 0.001));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.tap(find.byTooltip('Next channel'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(find.text('Two'), findsOneWidget);
    expect(controller().value.volume, closeTo(0.35, 0.001));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PlayerScreen)),
    );
    expect(container.read(playerVolumeProvider), closeTo(0.35, 0.001));
    await closePlayer(tester);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform locks landscape and unlocks when player closes', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      });
      await openPlayer(tester);
      expect(
        calls
            .where((c) => c.method == 'SystemChrome.setPreferredOrientations')
            .map((c) => c.arguments),
        [
          [
            'DeviceOrientation.landscapeLeft',
            'DeviceOrientation.landscapeRight',
          ],
        ],
      );
      await closePlayer(tester);
      expect(
        calls
            .lastWhere(
              (c) => c.method == 'SystemChrome.setPreferredOrientations',
            )
            .arguments,
        isEmpty,
      );
      debugDefaultTargetPlatformOverride = null;
    });
  }

  testWidgets('Android TV does not change device orientation', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final previous = kTvBuild;
    kTvBuild = true;
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() {
      kTvBuild = previous;
      debugDefaultTargetPlatformOverride = null;
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
    await openPlayer(tester);
    await closePlayer(tester);
    expect(
      calls.where((c) => c.method == 'SystemChrome.setPreferredOrientations'),
      isEmpty,
    );
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('one arrow reveals controls and focus survives the hide timer', (
    tester,
  ) async {
    await openPlayer(tester);
    await tester.pump(const Duration(seconds: 5));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    await tester.pump(const Duration(seconds: 5));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      isNot('player-play'),
    );
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      isNot('player-root'),
    );
    await closePlayer(tester);
  });

  testWidgets('Back hides focused controls before leaving the player', (
    tester,
  ) async {
    await openPlayer(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-root');
    await closePlayer(tester);
  });

  testWidgets('subtitle picker focuses Off and keeps focus while open', (
    tester,
  ) async {
    await openPlayer(tester);
    await tester.tap(find.byTooltip('Subtitles'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final off = find.widgetWithText(ListTile, 'Off');
    final focus = FocusManager.instance.primaryFocus;
    expect(focus, isNotNull);
    expect(
      focus?.context?.findAncestorWidgetOfExactType<ListTile>()?.title,
      isA<Text>(),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(FocusManager.instance.primaryFocus, same(focus));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(off, findsNothing);
    await closePlayer(tester);
  });
}
