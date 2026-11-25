import 'dart:async';
import 'dart:convert';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:zauxoflix/features/home/widgets/content_rail.dart';
import 'package:zauxoflix/features/home/widgets/hero_banner.dart';
import 'package:zauxoflix/core/app_platform.dart';
import 'package:zauxoflix/core/router/app_router.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/live/live_directory.dart';
import 'package:zauxoflix/data/live/live_providers.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/main.dart';
import 'package:zauxoflix/data/backend/remote_models.dart';
import 'package:zauxoflix/data/xtream/xtream_models.dart';
import 'package:zauxoflix/features/player/player_catalog.dart';
import 'support/auth_test_overrides.dart';
import 'supabase_auth_test.dart' show MemoryStore;
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/features/player/autoplay_preference.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/widgets/app_sheet.dart';
import 'package:video_player/video_player.dart';
import 'package:zauxoflix/features/player/player_volume.dart';
// Exercise focus without a native decoder or network stream.
// ignore: depend_on_referenced_packages
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/features/player/player_screen.dart';
import 'package:zauxoflix/features/player/seek_frame_reader_provider.dart';
import 'package:zauxoflix/features/player/seek_frames.dart';
import 'package:zauxoflix/features/player/webos_video_player.dart';
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

class _DelayedPlatform extends _VideoPlatform {
  final released = Completer<void>();
  final opens = <String>[];
  final fullscreenReleased = Completer<void>();
  bool delayFullscreen = false;
  final _events = <int, StreamController<VideoEvent>>{};
  StreamController<VideoEvent> get events => _events[opens.length]!;
  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    _events[playerId] = StreamController<VideoEvent>(onCancel: () async {});
    return _events[playerId]!.stream;
  }

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    opens.add(options.dataSource.uri!);
    return opens.length;
  }

  @override
  Future<void> dispose(int playerId) async {
    if (playerId == 1) await released.future;
    if (playerId == 2 && delayFullscreen) await fullscreenReleased.future;
    unawaited(_events.remove(playerId)?.close());
  }
}

mixin _DecoderFixture on VideoPlayerPlatform {
  final streams = <StreamController<VideoEvent>>[];
  final released = <int>[];
  final seeks = <(int, Duration)>[];
  bool rejectSeeks = false;
  Duration position = const Duration(seconds: 27);

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    streams.add(StreamController<VideoEvent>(onCancel: () async {}));
    return streams.length;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) =>
      streams[playerId - 1].stream;

  void ready() => streams.last.add(
    VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(minutes: 2),
      size: const Size(1280, 720),
    ),
  );

  void disconnect() => streams.last.addError(
    PlatformException(code: 'network', message: 'connection reset'),
  );

  @override
  Future<void> dispose(int playerId) async {
    released.add(playerId);
    await streams[playerId - 1].close();
  }

  @override
  Future<void> play(int playerId) async {}
  @override
  Future<void> pause(int playerId) async {}
  @override
  Future<void> setLooping(int playerId, bool looping) async {}
  @override
  Future<void> setVolume(int playerId, double volume) async {}
  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}
  @override
  Future<Duration> getPosition(int playerId) async => position;
  @override
  Future<void> seekTo(int playerId, Duration target) async {
    seeks.add((playerId, target));
    if (rejectSeeks) throw PlatformException(code: 'seek_unavailable');
  }

  @override
  Widget buildViewWithOptions(VideoViewOptions options) =>
      const ColoredBox(key: ValueKey('decoder-view'), color: Colors.black);
}

class _RecoveringPlatform extends _VideoPlatform with _DecoderFixture {}

class _FramePlatform extends WebOsVideoPlayer with _DecoderFixture {
  bool playing = false;

  @override
  Future<void> init() async {}

  @override
  Future<void> play(int playerId) async => playing = true;

  @override
  Future<void> pause(int playerId) async => playing = false;

  @override
  Future<void> seekTo(int playerId, Duration target) async {
    await super.seekTo(playerId, target);
    position = target;
  }
}

class _FilmstripReader implements SeekFrameReader {
  final requests = <Duration>[];
  final responses = <Completer<List<DecodedSeekFrame?>>>[];
  final centers = <void Function(List<DecodedSeekFrame?>)?>[];
  bool disposed = false;

  @override
  Future<List<DecodedSeekFrame?>> read(
    Duration time, {
    void Function(List<DecodedSeekFrame?>)? onFrames,
  }) {
    requests.add(time);
    centers.add(onFrames);
    final completion = Completer<List<DecodedSeekFrame?>>();
    responses.add(completion);
    return completion.future;
  }

  void resolve(int request, {bool centerOnly = false}) {
    final image = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACXBIWXMAAAsTAAALEwEAmpwY'
      'AAAADUlEQVQImWNgYGD4DwABBAEAX+XDSgAAAABJRU5ErkJggg==',
    );
    final frames = [
      for (var index = -1; index <= 1; index++)
        DecodedSeekFrame(requests[request] + Duration(seconds: index), image),
    ];
    if (centerOnly) {
      centers[request]?.call([frames[0], frames[1], null]);
    } else {
      responses[request].complete(frames);
    }
  }

  @override
  void dispose() => disposed = true;
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

  Future<void> openPlayer(
    WidgetTester tester, {
    PlayerArgs? args,
    SeekFrameReader? frameReader,
    Size size = const Size(1920, 1080),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          remotePlaybackProvider.overrideWith(_RemotePlayback.new),
          if (frameReader != null)
            seekFrameReaderProvider.overrideWithValue((_) => frameReader),
        ],
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

  for (final enabled in [true, false]) {
    testWidgets(
      'episode end remembers autoplay=$enabled, cancels and advances once',
      (tester) async {
        final platform = _RecoveringPlatform();
        VideoPlayerPlatform.instance = platform;
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final source = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Shows',
            serverUrl: 'https://example.test',
            username: '',
            password: '',
          ),
        );
        await db.replaceSeries(source, [
          SeriesItemsCompanion.insert(
            sourceId: source,
            seriesId: 7,
            name: 'Series',
          ),
        ]);
        final store = MemoryStore();
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            authenticatedOverride,
            keyValueStoreProvider.overrideWithValue(store),
            remotePlaybackProvider.overrideWith(_RemotePlayback.new),
            playerSeriesProvider(7).overrideWith(
              (ref) => const XtreamSeriesInfo(
                seasons: {
                  2: [
                    XtreamEpisode(
                      id: 22,
                      title: 'Second',
                      season: 2,
                      episodeNum: 1,
                    ),
                    XtreamEpisode(
                      id: 23,
                      title: 'Finale',
                      season: 2,
                      episodeNum: 2,
                    ),
                  ],
                  1: [
                    XtreamEpisode(
                      id: 21,
                      title: 'First',
                      season: 1,
                      episodeNum: 1,
                    ),
                  ],
                },
              ),
            ),
          ],
        );
        tester.view.physicalSize = enabled
            ? const Size(1280, 720)
            : const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> frames() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await tester.pump();
        }

        Future<void> finish() async {
          platform.streams.last.add(
            VideoEvent(eventType: VideoEventType.completed),
          );
          await frames();
          await frames();
        }

        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const ZauxoflixApp(),
            ),
          );
          await frames();
          final router = container.read(appRouterProvider);
          if (!enabled) {
            router.go('/settings');
            await frames();
            await tester.tap(find.widgetWithText(TextButton, 'Playback'));
            await frames();
            final toggle = find.widgetWithText(
              SwitchListTile,
              'Autoplay next episode',
            );
            await tester.scrollUntilVisible(
              toggle,
              230,
              scrollable: find.byType(Scrollable).first,
            );
            expect(tester.widget<SwitchListTile>(toggle).value, isTrue);
            await tester.tap(toggle);
            await frames();
            expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
            expect(await store.read(autoplayKey('test')), 'false');
            final restarted = ProviderContainer(
              overrides: [keyValueStoreProvider.overrideWithValue(store)],
            );
            expect(
              await restarted.read(autoplayPreferenceProvider('test').future),
              isFalse,
            );
            expect(
              await restarted.read(
                autoplayPreferenceProvider('another').future,
              ),
              isTrue,
            );
            restarted.dispose();
          }
          unawaited(
            router.push<void>(
              '/player',
              extra: PlayerArgs(
                items: [
                  PlayerItem(
                    title: 'Series',
                    subtitle: 'First',
                    url: 'https://example.test/1',
                    identity: PlaybackIdentity(
                      itemType: 'SERIES',
                      itemId: '7',
                      episodeId: '21',
                    ),
                  ),
                ],
              ),
            ),
          );
          await frames();
          platform.ready();
          await frames();
          platform.position = const Duration(seconds: 109);
          await frames();
          expect(find.text('Up next'), findsNothing);
          platform.position = const Duration(seconds: 117);
          await frames();
          if (enabled) {
            expect(find.text('Second'), findsOneWidget);
            expect(find.text('Starting in 3 s'), findsOneWidget);
            await tester.pump(const Duration(seconds: 2)); // Stalled playhead.
            expect(find.text('Starting in 3 s'), findsOneWidget);
            platform.position = const Duration(seconds: 118);
            await frames();
            expect(find.text('Starting in 2 s'), findsOneWidget);
            await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            await frames();
          } else {
            expect(find.text('Up next'), findsNothing);
          }
          expect(platform.streams, hasLength(1));
          await finish();
          expect(find.text('Play next episode'), findsOneWidget);
          final queued = await db.latestSeriesPosition(source, 7);
          expect(queued?.itemId, 22);
          expect(queued?.subtitle, 'S2 E1 — Second');
          await finish(); // Duplicate completion must not rearm a cancelled timer.
          await tester.pump(const Duration(seconds: 10));
          expect(platform.streams, hasLength(1));
          await tester.tap(find.text('Play next episode'));
          await frames();
          await frames();
          expect(platform.streams, hasLength(2));
          platform.position = const Duration(seconds: 27);
          platform.ready();
          await frames();
          await finish();
          if (enabled) {
            await tester.tap(find.text('Episodes'));
            await frames();
            await tester.pump(const Duration(seconds: 12));
            expect(platform.streams, hasLength(2));
            await tester.tap(find.byTooltip('Close'));
            await frames();
            await tester.pump(const Duration(seconds: 8));
          } else {
            await tester.pump(const Duration(seconds: 9));
            expect(platform.streams, hasLength(2));
            await tester.tap(find.text('Play next episode'));
          }
          await frames();
          await frames();
          expect(platform.streams, hasLength(3));
          platform.ready();
          await frames();
          await finish();
          expect(find.text('Episode finished'), findsOneWidget);
          await tester.pump(const Duration(seconds: 10));
          expect(platform.streams, hasLength(3));
          await tester.tap(find.text('Replay'));
          await frames();
          await frames();
          expect(platform.streams, hasLength(4));
          platform.ready();
          await frames();
          expect(platform.seeks, contains((4, Duration.zero)));
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox());
          container.dispose();
          final closing = db.close();
          await tester.pump(const Duration(seconds: 1));
          await closing;
        }
      },
    );
  }

  for (final size in [
    const Size(390, 844),
    const Size(832, 384),
    const Size(1280, 720),
  ]) {
    testWidgets(
      'episode drawer and Details share one player at ${size.width}',
      (tester) async {
        if (size == const Size(832, 384)) {
          debugDefaultTargetPlatformOverride = TargetPlatform.android;
          addTearDown(() => debugDefaultTargetPlatformOverride = null);
        }
        final platform = _RecoveringPlatform();
        VideoPlayerPlatform.instance = platform;
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        final source = await db.insertSource(
          SourcesCompanion.insert(
            name: 'Shows',
            serverUrl: 'https://example.test',
            username: '',
            password: '',
          ),
        );
        await db.replaceSeries(source, [
          SeriesItemsCompanion.insert(
            sourceId: source,
            seriesId: 7,
            name: 'Series',
          ),
        ]);
        await db.savePosition(
          PlaybackPositionsCompanion.insert(
            sourceId: source,
            kind: WatchKind.episode,
            itemId: 22,
            seriesId: const Value(7),
            title: 'Series',
            positionSecs: 45,
            durationSecs: 120,
            updatedAt: DateTime.now(),
          ),
        );
        final container = ProviderContainer(
          overrides: [
            authenticatedOverride,
            databaseProvider.overrideWithValue(db),
            remotePlaybackProvider.overrideWith(_RemotePlayback.new),
            playerSeriesProvider(7).overrideWith(
              (_) => const XtreamSeriesInfo(
                seasons: {
                  1: [
                    XtreamEpisode(
                      id: 21,
                      title: 'First',
                      season: 1,
                      episodeNum: 1,
                    ),
                  ],
                  2: [
                    XtreamEpisode(
                      id: 22,
                      title: 'Second',
                      season: 2,
                      episodeNum: 1,
                    ),
                    XtreamEpisode(
                      id: 23,
                      title: 'Third',
                      season: 2,
                      episodeNum: 2,
                    ),
                  ],
                },
              ),
            ),
          ],
        );
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> frames() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 450));
          await tester.pump();
          expect(tester.takeException(), isNull);
        }

        try {
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const ZauxoflixApp(),
            ),
          );
          await frames();
          final router = container.read(appRouterProvider);
          unawaited(
            router.push<void>(
              '/player',
              extra: PlayerArgs(
                items: [
                  PlayerItem(
                    title: 'Series',
                    subtitle: 'S1 E1 — First',
                    url: 'https://example.test/first',
                    identity: PlaybackIdentity(
                      itemType: 'SERIES',
                      itemId: '7',
                      episodeId: '21',
                    ),
                  ),
                ],
              ),
            ),
          );
          await frames();
          platform.ready();
          await frames();
          final player = tester.state(find.byType(PlayerScreen));
          await tester.ensureVisible(find.text('Episodes'));
          await tester.tap(find.text('Episodes'));
          await frames();
          expect(find.text('First'), findsOneWidget);
          await tester.tap(find.widgetWithText(OutlinedButton, 'Season 1'));
          await frames();
          expect(find.text('Select season'), findsOneWidget);
          await tester.tap(find.text('Season 2').last);
          await frames();
          expect(
            tester
                .widgetList<LinearProgressIndicator>(
                  find.byType(LinearProgressIndicator),
                )
                .map((w) => w.value),
            contains(45 / 120),
          );
          expect(platform.streams, hasLength(1));
          await tester.tap(find.text('Second'));
          await frames();
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await frames();
          expect(platform.released, contains(1));
          expect(platform.streams, hasLength(2));
          platform.ready();
          await frames();
          expect(platform.seeks, contains((2, const Duration(seconds: 45))));
          expect(find.byTooltip('Previous episode'), findsOneWidget);
          if (size == const Size(832, 384)) {
            final controls = {
              'Rewind': find.byTooltip('Rewind 10 seconds'),
              'Pause': find.byTooltip('Pause'),
              'Forward': find.byTooltip('Forward 30 seconds'),
              'Next': find.byTooltip('Next episode'),
              'Episodes': find.text('Episodes'),
              'Details': find.byTooltip('Series details'),
              'More': find.byTooltip('More playback options'),
            };
            final rewind = tester.getCenter(controls.values.first);
            for (final entry in controls.entries) {
              final control = entry.value;
              expect(
                control.hitTestable(),
                findsOneWidget,
                reason: '${entry.key} at ${tester.getCenter(control)}',
              );
              expect(tester.getCenter(control).dy, closeTo(rewind.dy, 2));
            }
          }
          final details = size == const Size(832, 384)
              ? find.byTooltip('Series details')
              : find.text('Series details');
          await tester.ensureVisible(details);
          await tester.tap(details);
          await frames();
          expect(router.state.uri.path, '/series/7');
          router.pop();
          await frames();
          expect(tester.state(find.byType(PlayerScreen)), same(player));
          expect(platform.streams, hasLength(2));
          await tester.ensureVisible(details);
          await tester.tap(details);
          await frames();
          await tester.ensureVisible(find.text('Season 2'));
          await tester.tap(find.text('Season 2'));
          await frames();
          final row = find.text('Third');
          await tester.ensureVisible(row);
          await tester.tap(row);
          await frames();
          await tester.runAsync(() => Future<void>.delayed(Duration.zero));
          await frames();
          expect(router.state.uri.path, '/player');
          expect(tester.state(find.byType(PlayerScreen)), same(player));
          expect(platform.streams, hasLength(3));
          for (final (count, episode) in [
            (4, 'S2 E1 — Second'),
            (5, 'S1 E1 — First'),
          ]) {
            platform.ready();
            await frames();
            await tester.tap(find.byTooltip('Previous episode'));
            await frames();
            await tester.runAsync(() => Future<void>.delayed(Duration.zero));
            await frames();
            expect(platform.streams, hasLength(count));
            expect(find.text(episode), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        } finally {
          if (size == const Size(832, 384)) {
            debugDefaultTargetPlatformOverride = null;
          }
          await tester.pumpWidget(const SizedBox());
          container.dispose();
          final closing = db.close();
          await tester.pump(const Duration(seconds: 1));
          await closing;
        }
      },
    );
  }

  testWidgets(
    'Home opens the player directly, resumes the saved movie and keeps Details available',
    (tester) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final id = await db.insertSource(
        SourcesCompanion.insert(
          name: 'test',
          serverUrl: '',
          username: '',
          password: '',
          sourceType: const Value(SourceType.m3u),
        ),
      );
      await db.replaceMovies(id, [
        MoviesCompanion.insert(
          sourceId: id,
          streamId: 11,
          name: 'John Wick',
          streamUrl: const Value('https://example.test/movie.mp4'),
        ),
      ]);
      await db.replaceLiveChannels(id, [
        LiveChannelsCompanion.insert(
          sourceId: id,
          streamId: 12,
          name: 'MBC',
          streamUrl: const Value('https://example.test/live'),
        ),
      ]);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          remotePlaybackProvider.overrideWith(_RemotePlayback.new),
          authenticatedOverride,
        ],
      );
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> frames() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
      }

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ZauxoflixApp(),
          ),
        );
        await frames();
        final router = container.read(appRouterProvider);
        Focus.of(tester.element(find.text('Play'))).requestFocus();
        await frames();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await frames();
        expect(
          tester
              .widget<PlayerScreen>(find.byType(PlayerScreen))
              .args
              .items
              .single
              .startAt,
          isNull,
        );
        router.pop();
        await frames();
        await db.savePosition(
          PlaybackPositionsCompanion.insert(
            sourceId: id,
            kind: WatchKind.movie,
            itemId: 11,
            title: 'John Wick',
            positionSecs: 47,
            durationSecs: 300,
            updatedAt: DateTime.now(),
          ),
        );
        await frames();
        await tester.tap(
          find.descendant(
            of: find.byType(HeroBanner),
            matching: find.text('Resume'),
          ),
        );
        await frames();
        final item = tester
            .widget<PlayerScreen>(find.byType(PlayerScreen))
            .args
            .items
            .single;
        expect(item.startAt, const Duration(seconds: 47));
        expect(item.identity?.itemId, '11');
        final player = tester.state(find.byType(PlayerScreen));
        final args = tester
            .widget<PlayerScreen>(find.byType(PlayerScreen))
            .args;
        await (db.update(db.sources)..where((s) => s.id.equals(id))).write(
          const SourcesCompanion(name: Value('Updated playlist')),
        );
        await frames();
        expect(tester.takeException(), isNull);
        expect(tester.state(find.byType(PlayerScreen)), same(player));
        expect(
          tester.widget<PlayerScreen>(find.byType(PlayerScreen)).args,
          same(args),
        );
        router.pop();
        await frames();
        await tester.tap(find.text('Details'));
        await frames();
        expect(router.state.uri.path, '/movie/11');
        router.pop();
        // External links may have a path without the in-memory arguments.
        for (final path in ['/player', '/remote']) {
          router.go(path);
          await frames();
          expect(router.state.uri.path, '/home');
          expect(tester.takeException(), isNull);
        }
        router.go('/search');
        await frames();
        await tester.enterText(find.byType(TextField), 'إم بي سي');
        await frames();
        expect(
          tester
              .widgetList<ContentRail>(find.byType(ContentRail))
              .where((r) => r.title == 'Live Channels')
              .single
              .items
              .single
              .title,
          'MBC',
        );
        expect(find.text('MBC'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'جون ويك');
        await frames();
        expect(
          tester
              .widgetList<ContentRail>(find.byType(ContentRail))
              .where((r) => r.title == 'Movies')
              .single
              .items
              .single
              .id,
          11,
        );
        unawaited(router.push<void>('/player', extra: args));
        await frames();
        await db.deleteSource(id);
        await frames();
        expect(router.state.uri.path, '/setup');
        expect(find.byType(PlayerScreen), findsNothing);
      } finally {
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        final closed = db.close();
        await tester.pump(const Duration(seconds: 1));
        await closed;
      }
    },
  );

  testWidgets(
    'rapid channel switches wait for native release and open only the last channel',
    (tester) async {
      const lastTitle = 'قناة الكأس الرياضية الدولية الثانية';
      final platform = _DelayedPlatform();
      VideoPlayerPlatform.instance = platform;
      await openPlayer(
        tester,
        size: const Size(390, 844),
        args: PlayerArgs(
          items: [
            for (final (index, name) in ['one', 'two', 'three'].indexed)
              PlayerItem(
                url: 'https://example.test/$name.ts',
                title: index == 2 ? lastTitle : name,
                subtitle: 'CH ${index + 1}',
                liveVersion: index == 0 ? 'HD' : 'Original',
                live: true,
              ),
          ],
        ),
      );
      expect(platform.opens, ['https://example.test/one.ts']);
      final header = find.byType(PlayerChannelHeader);
      expect(
        find.descendant(of: header, matching: find.text('one')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('CH 1  ·  HD')),
        findsOneWidget,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.channelUp);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.channelUp);
      await tester.pump();
      expect(platform.opens, hasLength(1));
      expect(
        find.descendant(of: header, matching: find.text(lastTitle)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('CH 3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: header, matching: find.text('قا')),
        findsOneWidget,
      );
      tester.view.physicalSize = const Size(844, 390);
      await tester.pump();
      expect(
        find.descendant(of: header, matching: find.text(lastTitle)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      platform.released.complete();
      await tester.pump();
      expect(platform.opens, [
        'https://example.test/one.ts',
        'https://example.test/three.ts',
      ]);
      await closePlayer(tester);
    },
  );

  testWidgets(
    'preview and fullscreen share the release barrier in both directions',
    (tester) async {
      final platform = _DelayedPlatform()..delayFullscreen = true;
      VideoPlayerPlatform.instance = platform;
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final id = await db.insertSource(
        SourcesCompanion.insert(
          name: 'fixture',
          serverUrl: 'http://example.test',
          username: 'u',
          password: 'p',
        ),
      );
      await db.replaceLiveChannels(id, [
        LiveChannelsCompanion.insert(
          sourceId: id,
          streamId: 2,
          name: 'Fixture Channel',
          categoryId: const Value('news'),
        ),
        LiveChannelsCompanion.insert(
          sourceId: id,
          streamId: 3,
          name: 'Related Channel',
          categoryId: const Value('news'),
          epgChannelId: const Value('related'),
        ),
      ]);
      final now = DateTime.now();
      await db.insertEpgBatch([
        EpgProgrammesCompanion.insert(
          sourceId: id,
          channelId: 'related',
          title: 'UEFA Champions League',
          startAt: now.subtract(const Duration(minutes: 10)),
          endAt: now.add(const Duration(minutes: 40)),
        ),
      ]);
      final channels = await db.select(db.liveChannels).get();
      final directory = buildLiveDirectory(channels, []);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          remotePlaybackProvider.overrideWith(_RemotePlayback.new),
          liveDirectoryProvider(
            id,
          ).overrideWith((ref) => Stream.value(directory)),
          authenticatedOverride,
        ],
      );
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Future<void> frames() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
      }

      try {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const ZauxoflixApp(),
          ),
        );
        await frames();
        final router = container.read(appRouterProvider);
        router.go('/live');
        await frames();
        final tile = find
            .descendant(
              of: find.byType(ListView),
              matching: find.text('Fixture Channel'),
            )
            .first;
        await tester.tap(tile);
        await frames();
        expect(platform.opens, hasLength(1));
        // A decoder that is still opening does not count as watched.
        Focus.of(tester.element(find.text('Recent'))).requestFocus();
        await frames();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await frames();
        expect(find.text('No recent channels yet'), findsOneWidget);
        await tester.tap(find.byTooltip('Add to Favorites'));
        await tester.tap(find.text('Favorites'));
        await frames();
        expect(tile, findsOneWidget);
        await tester.tap(tile);
        await frames();
        expect(find.byType(PlayerScreen), findsOneWidget);
        expect(platform.opens, hasLength(1));
        platform.released.complete();
        await frames();
        expect(platform.opens, hasLength(2));
        await (db.update(db.sources)..where((s) => s.id.equals(id))).write(
          const SourcesCompanion(name: Value('Updated live source')),
        );
        await frames();
        expect(tester.takeException(), isNull);
        expect(find.byType(PlayerScreen), findsOneWidget);
        await tester.tap(find.text('Channels'));
        await frames();
        expect(find.text('Related Channel'), findsOneWidget);
        expect(find.text('Schedule unavailable'), findsOneWidget);
        Focus.of(tester.element(find.text('Sports'))).requestFocus();
        await frames();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await frames();
        expect(find.text('UEFA Champions League'), findsOneWidget);
        expect(platform.opens, hasLength(2));
        await tester.tap(find.text('Related Channel'));
        await frames();
        expect(platform.opens, hasLength(2));
        platform.fullscreenReleased.complete();
        await frames();
        expect(platform.opens, hasLength(3));
        expect(platform.opens.toSet(), hasLength(2));
        expect(
          find.descendant(
            of: find.byType(PlayerChannelHeader),
            matching: find.text('Now · UEFA Champions League'),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byTooltip('Back'));
        await frames();
        expect(platform.opens, hasLength(4));
        expect(platform.opens[3], platform.opens[2]);
        platform.events.addError(
          PlatformException(code: 'network', message: 'connection lost'),
        );
        await tester.pump();
        expect(find.text('Retry'), findsNothing);
        await tester.pump(const Duration(seconds: 2));
        await tester.runAsync(() => Future<void>.delayed(Duration.zero));
        await frames();
        expect(platform.opens, hasLength(5));
        expect(find.text('Retry'), findsNothing);
        platform.events.addError(
          PlatformException(code: 'network', message: 'connection lost'),
        );
        await tester.pump();
        router.go('/home');
        await frames();
        await tester.pump(const Duration(seconds: 5));
        expect(platform.opens, hasLength(5));
      } finally {
        if (!platform.released.isCompleted) platform.released.complete();
        if (!platform.fullscreenReleased.isCompleted) {
          platform.fullscreenReleased.complete();
        }
        await tester.pumpWidget(const SizedBox());
        container.dispose();
        final closing = db.close();
        await tester.pump(const Duration(seconds: 1));
        await closing;
      }
    },
  );

  testWidgets(
    'playback works when the desktop keep-awake service is unavailable',
    (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMessageHandler(
            'dev.flutter.pigeon.wakelock_plus_platform_interface.WakelockPlusApi.toggle',
            (_) async => const StandardMessageCodec().encodeMessage([
              'ServiceUnknown',
              'No desktop portal',
              null,
            ]),
          );
      final platform = _RecoveringPlatform();
      VideoPlayerPlatform.instance = platform;
      await openPlayer(tester);
      platform.ready();
      await tester.pump();
      await tester.pump();
      expect(find.byType(VideoPlayer), findsOneWidget);
      await closePlayer(tester);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('recovery preserves controls, focus and the movie position', (
    tester,
  ) async {
    final platform = _RecoveringPlatform();
    VideoPlayerPlatform.instance = platform;
    await openPlayer(tester);
    platform.ready();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final focus = FocusManager.instance.primaryFocus;
    platform.streams.last.add(
      VideoEvent(eventType: VideoEventType.bufferingStart),
    );
    await tester.pump();
    expect(find.text('Buffering…'), findsNothing);
    expect(find.byType(VideoPlayer), findsOneWidget);
    platform.disconnect();
    await tester.pump();
    expect(find.text('Retry'), findsNothing);
    expect(find.byType(VideoPlayer), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(platform.streams, hasLength(2));
    expect(platform.released, [1]);
    expect(find.text('Loading…'), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(focus));
    platform.ready();
    await tester.pump();
    await tester.pump();
    expect(platform.seeks, contains((2, platform.position)));
    expect(find.byType(VideoPlayer), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    await closePlayer(tester);
  });

  testWidgets('pausing during backoff cancels the reopen until Play', (
    tester,
  ) async {
    final platform = _RecoveringPlatform();
    VideoPlayerPlatform.instance = platform;
    await openPlayer(tester);
    platform.ready();
    await tester.pump();
    platform.disconnect();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.pump(const Duration(seconds: 6));
    expect(platform.streams, hasLength(1));
    expect(find.text('Retry'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    expect(platform.streams, hasLength(2));
    await closePlayer(tester);
  });

  testWidgets(
    'a permanent failure shows Retry immediately and never takes the stream slot again',
    (tester) async {
      final platform = _RecoveringPlatform();
      VideoPlayerPlatform.instance = platform;
      await openPlayer(tester);
      platform.streams.single.addError(
        PlatformException(code: 'http', message: 'network HTTP 403'),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
      await tester.pump(const Duration(seconds: 25));
      expect(platform.streams, hasLength(1));
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-retry');
      await closePlayer(tester);
    },
  );

  testWidgets(
    'an opening decoder that sends no event times out and can be retried',
    (tester) async {
      final platform = _DelayedPlatform()..released.complete();
      VideoPlayerPlatform.instance = platform;
      await openPlayer(tester);
      await tester.pump(const Duration(seconds: 31));
      await tester.pump();
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(platform.opens, hasLength(2));
      expect(find.text('Retry'), findsNothing);
      await closePlayer(tester);
    },
  );

  testWidgets(
    'player uses system volume on LG and preserves app gain across channels elsewhere',
    (tester) async {
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

      if (isWebOsPlatform) {
        expect(find.byTooltip('Player volume'), findsNothing);
        await closePlayer(tester);
        return;
      }
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
    },
  );

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('$platform follows rotation with a manual override', (
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
      final video = _RecoveringPlatform();
      VideoPlayerPlatform.instance = video;
      List<Object?> orientationRequests() => calls
          .where(
            (call) => call.method == 'SystemChrome.setPreferredOrientations',
          )
          .map((call) => call.arguments as Object?)
          .toList();
      try {
        await openPlayer(tester, size: const Size(390, 844));
        video.ready();
        await tester.pump();
        await tester.pump();
        expect(orientationRequests(), isEmpty);
        if (isWebOsPlatform) return;

        await tester.tap(find.byTooltip('Rotate player'));
        await tester.pump();
        expect(orientationRequests(), [
          [
            'DeviceOrientation.landscapeLeft',
            'DeviceOrientation.landscapeRight',
          ],
        ]);
        tester.view.physicalSize = const Size(844, 390);
        await tester.pump();
        expect(video.streams, hasLength(1));
        expect(find.byType(Slider), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('More playback options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Follow device rotation'));
        await tester.pumpAndSettle();
        expect(orientationRequests().last, isEmpty);

        await tester.tap(find.byTooltip('Rotate player'));
        await tester.pump();
        expect(orientationRequests().last, ['DeviceOrientation.portraitUp']);
        await closePlayer(tester);
        expect(orientationRequests().last, isEmpty);
      } finally {
        await closePlayer(tester);
        messenger.setMockMethodCallHandler(SystemChannels.platform, null);
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  testWidgets(
    'landscape phone respects its cutout and separates the playback toolbar',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      try {
        await openPlayer(tester);
        for (final size in [const Size(832, 384), const Size(640, 320)]) {
          tester.view.physicalSize = size;
          tester.view.padding = const FakeViewPadding(left: 32, right: 8);
          addTearDown(tester.view.resetPadding);
          await tester.pump();
          final back = tester.getRect(find.byTooltip('Back'));
          final rewind = tester.getRect(find.byTooltip('Rewind 10 seconds'));
          final more = tester.getRect(find.byTooltip('More playback options'));
          expect(back.left, greaterThanOrEqualTo(32));
          expect(back.bottom, lessThan(rewind.top));
          expect(more.center.dy, closeTo(rewind.center.dy, 1));
          expect(
            more.left,
            greaterThan(
              tester.getRect(find.byTooltip('Forward 30 seconds')).right,
            ),
          );
          expect(more.right, lessThanOrEqualTo(size.width - 8));
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.byTooltip('More playback options'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Picture fit'), findsOneWidget);
        await tester.tap(find.text('Picture fit'));
        await tester.pumpAndSettle();
        expect(find.text('Fill the screen and crop the edges'), findsOneWidget);
        await tester.tap(find.text('Fill'));
        await tester.pumpAndSettle();
        expect(find.text('Playback options'), findsOneWidget);
        expect(find.text('Fill'), findsOneWidget);
      } finally {
        await closePlayer(tester);
        debugDefaultTargetPlatformOverride = null;
      }
    },
  );

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

  testWidgets(
    'TV controls hide after inactivity and an arrow brings them back',
    (tester) async {
      final previous = kTvBuild;
      kTvBuild = true;
      addTearDown(() => kTvBuild = previous);
      await openPlayer(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
      await tester.pump(const Duration(seconds: 3));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(seconds: 2));
      expect(
        FocusManager.instance.primaryFocus?.debugLabel,
        isNot('player-root'),
      );
      await tester.pump(const Duration(seconds: 3));
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-root');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
      await closePlayer(tester);
    },
  );

  testWidgets('TV timeline seeks by ten seconds and vertical arrows leave it', (
    tester,
  ) async {
    final previous = kTvBuild;
    kTvBuild = true;
    addTearDown(() => kTvBuild = previous);
    final video = _RecoveringPlatform();
    VideoPlayerPlatform.instance = video;
    await openPlayer(tester);
    video.ready();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    final timeline = find.byWidgetPredicate(
      (widget) =>
          widget is Slider && widget.focusNode?.debugLabel == 'player-timeline',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-timeline');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(tester.widget<Slider>(timeline).value, 37000);
    final previewTime = find.byKey(const ValueKey('seek-preview-time'));
    expect(tester.widget<Text>(previewTime).data, '00:37');
    expect(
      tester.getBottomLeft(previewTime).dy,
      lessThan(tester.getCenter(timeline).dy),
    );
    expect(video.seeks, isEmpty);
    await tester.pump(const Duration(milliseconds: 550));
    expect(video.seeks, [(1, const Duration(seconds: 37))]);
    video.position = const Duration(seconds: 37);
    await tester.pump(const Duration(milliseconds: 420));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(video.seeks.last, (1, const Duration(seconds: 27)));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    tester.widget<Slider>(timeline).focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      isNot('player-timeline'),
    );
    expect(video.seeks, hasLength(2));
    await closePlayer(tester);
  });

  testWidgets('remote scrub accepts repeated arrows and OK toggles playback', (
    tester,
  ) async {
    final previous = kTvBuild;
    kTvBuild = true;
    addTearDown(() => kTvBuild = previous);
    final video = _RecoveringPlatform();
    VideoPlayerPlatform.instance = video;
    await openPlayer(tester);
    video.ready();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 4));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-timeline');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    await tester.pump(const Duration(milliseconds: 500));
    expect(video.seeks, [(1, const Duration(seconds: 47))]);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPause);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaRewind);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byTooltip('Play'), findsOneWidget);
    expect(video.seeks.last, (1, const Duration(seconds: 37)));
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlay);
    await tester.pump();
    expect(find.byTooltip('Pause'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 550));
    expect(video.seeks.last, (1, const Duration(seconds: 67)));
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-forward');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(find.byTooltip('Play'), findsOneWidget);
    await closePlayer(tester);
  });

  testWidgets('TV skip buttons and media keys preserve focus while seeking', (
    tester,
  ) async {
    final previous = kTvBuild;
    kTvBuild = true;
    addTearDown(() => kTvBuild = previous);
    final video = _RecoveringPlatform();
    VideoPlayerPlatform.instance = video;
    await openPlayer(tester);
    video.ready();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 440));
    final forward = tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.forward_30_rounded),
        )
        .focusNode!;
    final rewind = tester
        .widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.replay_10_rounded),
        )
        .focusNode!;
    forward.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 550));
    expect(video.seeks, [(1, const Duration(seconds: 87))]);
    expect(forward.hasPrimaryFocus, isTrue);
    video.position = const Duration(seconds: 87);
    await tester.pump(const Duration(seconds: 5));
    expect(forward.hasPrimaryFocus, isTrue);
    rewind.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.sendKeyEvent(LogicalKeyboardKey.mediaRewind);
    await tester.pump(const Duration(milliseconds: 550));
    expect(video.seeks.last, (1, const Duration(seconds: 67)));
    expect(rewind.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-timeline');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(rewind.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-play');
    await closePlayer(tester);
  });

  testWidgets(
    'LG seeks promptly and shows the center frame before the strip finishes',
    (tester) async {
      final previous = kTvBuild;
      kTvBuild = true;
      addTearDown(() => kTvBuild = previous);
      final video = _FramePlatform()
        ..position = const Duration(milliseconds: 27280);
      final reader = _FilmstripReader();
      VideoPlayerPlatform.instance = video;
      await openPlayer(tester, frameReader: reader);
      video.ready();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
      final view = find.byKey(const ValueKey('decoder-view'));
      final viewElement = tester.element(view);
      final fullSize = tester.getSize(view);
      final time = find.byKey(const ValueKey('seek-preview-time'));
      final center = find.byKey(const ValueKey('seek-frame-1'));
      final bar = find.byType(Slider);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(reader.requests, [const Duration(milliseconds: 37280)]);
      expect(video.seeks, isEmpty);
      expect(video.streams, hasLength(1));
      expect(video.playing, isTrue);
      expect(center, findsNothing);
      expect(tester.getSize(view), fullSize);
      expect(tester.element(view), same(viewElement));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      reader.resolve(0);
      await tester.pump();
      expect(center, findsNothing);
      expect(reader.requests, [
        const Duration(milliseconds: 37280),
        const Duration(milliseconds: 17280),
      ]);
      reader.resolve(1, centerOnly: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));
      expect(tester.widget<Text>(time).data, '00:17');
      expect(center, findsOneWidget);
      expect(find.byKey(const ValueKey('seek-frame-2')), findsNothing);
      expect(video.seeks, [(1, const Duration(milliseconds: 17280))]);
      reader.resolve(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      for (var slot = 0; slot < 3; slot++) {
        expect(find.byKey(ValueKey('seek-frame-$slot')), findsOneWidget);
      }
      final first = find.byKey(const ValueKey('seek-frame-0'));
      final last = find.byKey(const ValueKey('seek-frame-2'));
      expect(
        tester.getSize(center).width,
        greaterThan(tester.getSize(first).width),
      );
      expect(tester.getCenter(first).dx, lessThan(tester.getCenter(center).dx));
      expect(
        tester.getCenter(last).dx,
        greaterThan(tester.getCenter(center).dx),
      );
      expect(
        tester.getBottomLeft(center).dy,
        lessThan(tester.getCenter(bar).dy),
      );
      expect(video.seeks, [(1, const Duration(milliseconds: 17280))]);
      expect(tester.getSize(view), fullSize);
      await tester.pump(const Duration(milliseconds: 1950));
      expect(time, findsNothing);
      expect(video.playing, isTrue);
      expect(tester.getSize(view), fullSize);
      expect(tester.element(view), same(viewElement));
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'player-timeline');
      await closePlayer(tester);
      expect(reader.disposed, isTrue);
    },
  );

  testWidgets(
    'touch timeline seeks in both directions and recovers from rejection',
    (tester) async {
      final video = _RecoveringPlatform();
      VideoPlayerPlatform.instance = video;
      await openPlayer(tester);
      tester.view.physicalSize = const Size(832, 384);
      video.ready();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final track = tester.getRect(find.byType(Slider));
      final drag = await tester.startGesture(
        Offset(track.left + track.width * .23, track.center.dy),
      );
      await drag.moveTo(
        Offset(track.left + track.width * .75, track.center.dy),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('seek-preview-time')), findsOneWidget);
      expect(video.seeks, isEmpty);
      await drag.up();
      await tester.pump();
      final later = video.seeks.single.$2;
      expect(later.inSeconds, greaterThan(80));
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPause);
      await tester.pump();
      await tester.tapAt(
        Offset(track.left + track.width * .2, track.center.dy),
      );
      await tester.pump();
      expect(video.seeks.last.$2.inSeconds, lessThan(30));
      expect(find.byTooltip('Play'), findsOneWidget);
      video.rejectSeeks = true;
      await tester.tap(find.byTooltip('Forward 30 seconds'));
      await tester.pump();
      expect(find.text('Unable to seek in this stream.'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      await tester.tap(find.byTooltip('Play'));
      await tester.pump();
      expect(find.byTooltip('Pause'), findsOneWidget);
      await closePlayer(tester);
    },
  );

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
    if (!isFvpPlatform) {
      expect(find.byTooltip('Audio & subtitles'), findsNothing);
      await closePlayer(tester);
      return;
    }
    await tester.tap(find.byTooltip('Audio & subtitles'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final off = find.widgetWithText(AppSheetOption, 'Off');
    final focus = FocusManager.instance.primaryFocus;
    expect(focus, isNotNull);
    expect(
      focus?.context?.findAncestorWidgetOfExactType<AppSheetOption>()?.title,
      'Off',
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
