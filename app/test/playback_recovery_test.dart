import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:zauxoflix/features/player/playback_recovery.dart';

const vod = VideoPlayerValue(
  duration: Duration(minutes: 2),
  isInitialized: true,
  isPlaying: true,
);
const live = VideoPlayerValue(
  duration: Duration.zero,
  isInitialized: true,
  isPlaying: true,
  isCompleted: true,
);

class _Playback {
  _Playback(this.tester) {
    final start = tester.binding.clock.now();
    budget = PlaybackRetryBudget(
      now: () => tester.binding.clock.now().difference(start),
    );
  }
  final WidgetTester tester;
  late final PlaybackRetryBudget budget;
  final failures = <String>[];
  int opens = 0;

  PlaybackRecovery tune({
    bool isLive = false,
    bool lg = false,
    String url = 'https://example.test/movie',
  }) {
    final recovery = PlaybackRecovery(
      url: url,
      budget: budget,
      live: isLive,
      webOs: lg,
      reopen: () => opens++,
      onFailure: failures.add,
    );
    addTearDown(recovery.dispose);
    return recovery;
  }
}

void main() {
  testWidgets(
    'playable buffer and motion during backoff keep the same decoder',
    (tester) async {
      final p = _Playback(tester);
      final r = p.tune();
      final buffered = vod.copyWith(
        isBuffering: true,
        buffered: [DurationRange(Duration.zero, const Duration(seconds: 15))],
      );
      r.playing(buffered);
      for (var i = 1; i <= 8; i++) {
        await tester.pump(const Duration(seconds: 1));
        r.observe(buffered.copyWith(position: Duration(seconds: i)));
      }
      await tester.pump(const Duration(seconds: 5));
      r.observe(vod.copyWith(position: const Duration(seconds: 9)));
      await tester.pump(const Duration(seconds: 2));
      expect(p.opens, 0);
      expect(p.failures, isEmpty);
      r.dispose();
    },
  );

  testWidgets(
    'a stalled playhead gets two reopens including duplicate errors',
    (tester) async {
      final p = _Playback(tester);
      final r = p.tune();
      r.playing(vod);
      await tester.pump(const Duration(seconds: 4));
      expect(p.opens, 0);
      await tester.pump(const Duration(seconds: 3));
      expect(p.opens, 1);
      r.failure('connection reset');
      r.failure('connection reset');
      await tester.pump(const Duration(seconds: 4));
      expect(p.opens, 2);
      r.failure('503 service unavailable');
      expect(p.failures, hasLength(1));
      await tester.pump(const Duration(minutes: 1));
      expect(p.opens, 2);
    },
  );

  testWidgets(
    'stall grace and a hung replacement share one 20 second deadline',
    (tester) async {
      final p = _Playback(tester);
      final r = p.tune()..playing(vod);
      await tester.pump(const Duration(seconds: 19));
      expect(p.opens, 1);
      expect(p.failures, isEmpty);
      await tester.pump(const Duration(seconds: 1));
      expect(p.failures, hasLength(1));
      r.dispose();
    },
  );

  testWidgets(
    'a zero-duration live clock can play, buffer and recover in place',
    (tester) async {
      final p = _Playback(tester);
      final r = p.tune(isLive: true)..playing(live);
      await tester.pump(const Duration(minutes: 1));
      r.observe(live.copyWith(isBuffering: true));
      await tester.pump(const Duration(seconds: 5));
      r.observe(live);
      await tester.pump(const Duration(seconds: 25));
      expect(p.opens, 0);
      expect(p.failures, isEmpty);
      r.dispose();
    },
  );

  testWidgets('preview and fullscreen share the rolling provider allowance', (
    tester,
  ) async {
    final p = _Playback(tester);
    for (var i = 0; i < 4; i++) {
      final r = p.tune(url: 'https://example.test/channel/$i');
      r.failure('network unreachable');
      await tester.pump(const Duration(seconds: 2));
      r.dispose();
    }
    expect(p.opens, 3);
    expect(p.failures, hasLength(1));
    await tester.pump(const Duration(minutes: 10));
    final r = p.tune()..failure('network unreachable');
    await tester.pump(const Duration(seconds: 2));
    expect(p.opens, 4);
    r.dispose();
  });

  testWidgets('server delay, permanent failures and LG status codes', (
    tester,
  ) async {
    final p = _Playback(tester);
    p.tune().failure('HTTP 429\nRetry-After: 90');
    p.tune().failure('network HTTP 403');
    p.tune(lg: true).failure('webOS 401 HLS resource not found');
    p.tune(url: '/local/video').failure('network error');
    final lg = p.tune(lg: true)..failure('webOS 403 HLS gateway timeout');
    final waited = p.tune()..failure('HTTP 503\nRetry-After: 6');
    await tester.pump(const Duration(seconds: 5));
    expect(p.opens, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(p.opens, 2);
    expect(p.failures, hasLength(4));
    lg.dispose();
    waited.dispose();
  });

  testWidgets('cancelled retries and completed movies never reopen', (
    tester,
  ) async {
    final p = _Playback(tester);
    p.tune()
      ..failure('socket closed')
      ..dispose();
    final movie = p.tune()..playing(vod);
    movie.observe(vod.copyWith(isCompleted: true, isPlaying: false));
    await tester.pump(const Duration(minutes: 1));
    expect(p.opens, 0);
    expect(p.failures, isEmpty);
    movie.dispose();
  });
}
