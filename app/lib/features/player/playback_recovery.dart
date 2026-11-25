import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:io' show HttpDate, HttpException;

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Shared by the preview and fullscreen player, including across channel changes.
class PlaybackRetryBudget {
  PlaybackRetryBudget({Duration Function()? now})
    : now = now ?? (Stopwatch()..start()).elapsedTime;

  final Duration Function() now;
  final _opens = <String, List<Duration>>{};

  bool take(String origin) {
    final at = now();
    for (final times in _opens.values) {
      times.removeWhere((t) => at - t >= const Duration(minutes: 10));
    }
    _opens.removeWhere((_, times) => times.isEmpty);
    final times = _opens.putIfAbsent(origin, () => []);
    if (times.length >= 3) return false;
    times.add(at);
    return true;
  }
}

extension on Stopwatch {
  Duration elapsedTime() => elapsed;
}

/// A single tune owns the recovery timers through all of its decoder opens.
class PlaybackRecovery {
  PlaybackRecovery({
    required String url,
    required this.budget,
    required this.live,
    required this.webOs,
    required this.reopen,
    required this.onFailure,
    Random? random,
  }) : _origin = _httpOrigin(url),
       _random = random ?? Random() {
    _startup = Timer(
      const Duration(seconds: 30),
      () => _fail('The stream took too long to open.'),
    );
  }

  final PlaybackRetryBudget budget;
  final bool live;
  final bool webOs;
  final void Function() reopen;
  final void Function(String) onFailure;
  final String? _origin;
  final Random _random;
  static const _grace = Duration(seconds: 5);
  static const _limit = Duration(seconds: 20);
  Timer? _startup, _stall, _deadline, _retry, _clocklessHealth;
  Duration? _incidentStart, _stableSince;
  Duration _position = Duration.zero;
  Duration? _lastMotion;
  bool _clockAdvanced = false;
  bool _playing = false;
  bool _closed = false;
  bool _hardFailure = false;
  bool hasPlayed = false;
  int _opens = 0;

  static String? _httpOrigin(String url) {
    final uri = Uri.tryParse(url);
    return uri != null &&
            (uri.isScheme('http') || uri.isScheme('https')) &&
            uri.host.isNotEmpty
        ? uri.origin
        : null;
  }

  void playing(VideoPlayerValue value) {
    if (_closed || _hardFailure || value.hasError) return;
    _playing = true;
    hasPlayed = true;
    _startup?.cancel();
    _position = value.position;
    observe(value);
  }

  void observe(VideoPlayerValue value) {
    if (_closed) return;
    if (value.hasError) {
      failure(value.errorDescription ?? '');
      return;
    }
    if (!_playing || _hardFailure || _origin == null) return;
    // video_player also sets isCompleted when a live clock and duration are
    // both zero, even while audio and video are playing normally.
    if (value.isCompleted && !live && value.duration > Duration.zero) {
      _clearIncident();
      _playing = false;
      return;
    }
    final advanced = value.position > _position;
    final moved = value.position != _position;
    _position = value.position;
    if (advanced) _clockAdvanced = true;
    if (moved) {
      _lastMotion = budget.now();
      // During backoff, the original decoder can still recover in place.
      _retry?.cancel();
      _retry = null;
      if (_incidentStart != null && advanced) {
        _stableSince ??= budget.now();
        if (_opens == 0 ||
            budget.now() - _stableSince! >= const Duration(seconds: 2)) {
          _recovered();
        }
      }
    }
    final watch =
        value.isBuffering ||
        (live && value.isCompleted && !value.isPlaying) ||
        ((value.isPlaying || _clockAdvanced) && (!live || _clockAdvanced));
    if (watch) {
      _clocklessHealth?.cancel();
      _clocklessHealth = null;
      _lastMotion ??= budget.now();
      _stall ??= Timer(_grace, _checkStall);
    } else if (live &&
        !_clockAdvanced &&
        value.isPlaying &&
        !value.isBuffering) {
      // Some TV live inputs never expose a clock. Buffering-end and continued
      // playing are the only health signals available on those inputs.
      _stall?.cancel();
      _stall = null;
      _lastMotion = null;
      _retry?.cancel();
      _retry = null;
      if (_incidentStart != null) {
        _clocklessHealth ??= Timer(const Duration(seconds: 2), _recovered);
      }
    }
  }

  void _checkStall() {
    final remaining = _grace - (budget.now() - _lastMotion!);
    if (remaining > Duration.zero) {
      _stall = Timer(remaining, _checkStall);
      return;
    }
    _stall = null;
    _schedule(alreadyStalled: _grace);
  }

  // Native players rarely expose headers. Obey a server delay when they do.
  static Duration? _retryAfter(String message) {
    final match = RegExp(
      r'retry-after\s*:\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(message);
    if (match == null) return null;
    final raw = match[1]!.trim();
    final seconds = int.tryParse(raw);
    if (seconds != null) {
      return seconds >= 0 && seconds <= _limit.inSeconds
          ? Duration(seconds: seconds)
          : _limit;
    }
    try {
      final delay = HttpDate.parse(raw).difference(DateTime.now().toUtc());
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return _limit;
    } on HttpException {
      return _limit;
    }
  }

  void failure(Object error) {
    if (_closed || _hardFailure) return;
    final message = error is PlatformException
        ? (error.message ?? error.code)
        : error.toString();
    final lower = message.toLowerCase();
    // Pipeline status 403 on LG means HLS gateway timeout. The native prefix
    // keeps that distinct from an HTTP 403 sent by the provider.
    final lgStatus = webOs
        ? RegExp(r'^webos (\d+)\b').firstMatch(lower)?.group(1)
        : null;
    final retryAfter = _retryAfter(message);
    final rateLimited = RegExp(r'\b429\b').hasMatch(lower);
    final temporary = lgStatus != null
        ? const {'102', '300', '402', '403', '1000', '61440'}.contains(lgStatus)
        : rateLimited
        ? retryAfter != null
        : error is TimeoutException ||
              RegExp(
                r'\b(network|connection|socket|timeout|timed out|unreachable|disconnected|502|503|504|408)\b',
              ).hasMatch(lower);
    final permanent =
        RegExp(
          r'\b(unsupported|forbidden|unauthorized|drm)\b',
        ).hasMatch(lower) ||
        (lgStatus == null &&
            RegExp(r'\b(400|401|403|404|410)\b').hasMatch(lower));
    if (_origin == null || permanent || !temporary) {
      _fail('The player could not play this stream.');
      return;
    }
    _hardFailure = true;
    _stall?.cancel();
    _clocklessHealth?.cancel();
    _retry?.cancel();
    _retry = null;
    _schedule(retryAfter: retryAfter);
  }

  void _schedule({
    Duration alreadyStalled = Duration.zero,
    Duration? retryAfter,
  }) {
    if (_closed || _retry != null) return;
    _stableSince = null;
    if (_incidentStart == null) {
      _incidentStart = budget.now() - alreadyStalled;
      _deadline = Timer(
        _limit - alreadyStalled,
        () => _fail('The stream did not recover.'),
      );
    }
    if (_opens >= 2) {
      _fail('The stream did not recover.');
      return;
    }
    final delay = _opens == 0
        ? 500 + _random.nextInt(1001)
        : 2000 + _random.nextInt(2001);
    var wait = Duration(milliseconds: delay);
    if (retryAfter != null && retryAfter > wait) wait = retryAfter;
    if (budget.now() - _incidentStart! + wait >= _limit) {
      _fail('The stream did not recover.');
      return;
    }
    _retry = Timer(wait, () {
      _retry = null;
      if (!budget.take(_origin!)) {
        _fail('The stream did not recover.');
        return;
      }
      _opens++;
      _playing = false;
      _hardFailure = false;
      _clockAdvanced = false;
      _lastMotion = null;
      _position = Duration.zero;
      _stall?.cancel();
      _stall = null;
      _clocklessHealth?.cancel();
      _clocklessHealth = null;
      reopen();
    });
  }

  void _record(String outcome) {
    final start = _incidentStart;
    if (start != null) {
      developer.Timeline.instantSync(
        'Playback recovery',
        arguments: {
          'outcome': outcome,
          'live': live,
          'reopens': _opens,
          'elapsedMs': (budget.now() - start).inMilliseconds,
        },
      );
    }
  }

  void _recovered() {
    _record('recovered');
    _clearIncident();
  }

  void _clearIncident() {
    for (final timer in [_retry, _stall, _deadline, _clocklessHealth]) {
      timer?.cancel();
    }
    _retry = _stall = _deadline = _clocklessHealth = null;
    _stableSince = _incidentStart = _lastMotion = null;
    _opens = 0;
  }

  void _fail(String reason) {
    if (_closed) return;
    _record('failed');
    dispose();
    onFailure(reason);
  }

  void dispose() {
    _closed = true;
    _startup?.cancel();
    _clearIncident();
  }
}
