import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart' show BooleanExpressionOperators, Variable;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../db/app_database.dart';
import '../providers.dart';

String localDay(DateTime now) => now.toIso8601String().split('T').first;
final recommendationNowProvider = Provider<DateTime Function()>(
  (_) => DateTime.now,
);
typedef HomeTime = ({String day, int part});
final homeTimeProvider = NotifierProvider<HomeClock, HomeTime>(HomeClock.new);

class HomeClock extends Notifier<HomeTime> {
  Timer? _timer;
  @override
  HomeTime build() {
    ref.onDispose(() => _timer?.cancel());
    return _schedule();
  }

  HomeTime _schedule() {
    final now = ref.read(recommendationNowProvider)().toLocal();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      (now.hour ~/ 4 + 1) * 4,
    );
    _timer?.cancel();
    _timer = Timer(next.difference(now), refresh);
    return (day: localDay(now), part: now.hour ~/ 4);
  }

  void refresh() {
    state = _schedule();
  }
}

final recommendationDayProvider = Provider<String>(
  (ref) => ref.watch(homeTimeProvider.select((v) => v.day)),
);

typedef Snapshot = ({String day, Map<String, dynamic> data});
typedef CacheId = ({int source, String slot});
final dailyCacheProvider = Provider<DailyCache>(
  (ref) => DailyCache(ref.watch(databaseProvider)),
);

class DailyCache {
  DailyCache(this.db);
  final AppDatabase db;
  final _pending = <(CacheId, String, int), Future<Snapshot>>{};
  final _recent = <CacheId, Snapshot?>{};
  final _reads = <CacheId, Future<Snapshot?>>{};
  final _failed = <(CacheId, String)>{};
  String? _maintenanceDay;
  int? _generation;

  Future<Snapshot?> read(CacheId id) {
    final generation = db.recommendationGeneration;
    if (_generation != generation) {
      _generation = generation;
      _recent.clear();
      _reads.clear();
      _failed.clear();
    }
    if (_recent.containsKey(id)) {
      final snapshot = _recent.remove(id);
      _remember(id, snapshot);
      return Future.value(snapshot);
    }
    return _reads.putIfAbsent(id, () async {
      try {
        final snapshot = await _readStored(id);
        if (generation == db.recommendationGeneration) {
          _remember(id, snapshot);
        }
        return snapshot;
      } finally {
        if (_generation == generation) unawaited(_reads.remove(id));
      }
    });
  }

  void _remember(CacheId id, Snapshot? snapshot) {
    _recent.remove(id);
    _recent[id] = snapshot;
    // Keep recent decoded payloads small. The database is the durable cache.
    if (_recent.length > 24) _recent.remove(_recent.keys.first);
  }

  Future<Snapshot?> _readStored(CacheId id) async {
    final row =
        await (db.select(db.recommendationSnapshots)..where(
              (r) => r.sourceId.equals(id.source) & r.slot.equals(id.slot),
            ))
            .getSingleOrNull();
    if (row == null) return null;
    try {
      final data = jsonDecode(row.payload);
      if (data is Map<String, dynamic>) return (day: row.day, data: data);
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<Snapshot> get(
    CacheId id,
    String day,
    Future<Map<String, dynamic>> Function(Snapshot? previous) build, {
    bool allowStale = false,
    bool Function(Map<String, dynamic>)? persist,
  }) {
    final key = (id, day, db.recommendationGeneration);
    return _pending.putIfAbsent(
      key,
      () => _get(id, day, build, allowStale, persist).whenComplete(() {
        _pending.remove(key);
      }),
    );
  }

  Future<Snapshot> _get(
    CacheId id,
    String day,
    Future<Map<String, dynamic>> Function(Snapshot?) build,
    bool allowStale,
    bool Function(Map<String, dynamic>)? persist,
  ) async {
    final generation = db.recommendationGeneration;
    final old = await read(id);
    void checkScope() {
      if (id.source != 0 && generation != db.recommendationGeneration) {
        throw StateError('The active library changed');
      }
    }

    checkScope();
    if (old?.day == day) return old!;
    final key = (id, day);
    _failed.removeWhere((k) => k.$2 != day);
    if (allowStale && _failed.contains(key)) {
      if (old != null) return old;
      throw StateError('Chart unavailable');
    }
    try {
      final data = await build(old);
      checkScope();
      if (generation == db.recommendationGeneration &&
          (persist?.call(data) ?? true)) {
        if (_maintenanceDay == null || day.compareTo(_maintenanceDay!) > 0) {
          _maintenanceDay = day;
          final cutoff = localDay(
            DateTime.parse(day).subtract(const Duration(days: 35)),
          );
          await db.customStatement(
            "DELETE FROM recommendation_snapshots WHERE slot LIKE 'related.v1/%' AND day < ?",
            [cutoff],
          );
        }
        // Keep a late response from yesterday from replacing today's snapshot.
        final written = await db.customUpdate(
          """
          INSERT INTO recommendation_snapshots(source_id,slot,day,payload)
          SELECT ?1,?2,?3,?4 WHERE ?1=0 OR EXISTS(SELECT 1 FROM sources WHERE id=?1)
          ON CONFLICT(source_id,slot) DO UPDATE SET day=excluded.day,payload=excluded.payload
          WHERE recommendation_snapshots.day<=excluded.day
        """,
          variables: [
            Variable.withInt(id.source),
            Variable.withString(id.slot),
            Variable.withString(day),
            Variable.withString(jsonEncode(data)),
          ],
        );
        if (written > 0 &&
            generation == db.recommendationGeneration &&
            (_recent[id]?.day.compareTo(day) ?? 0) <= 0) {
          _remember(id, (day: day, data: data));
        }
      }
      checkScope();
      return (day: day, data: data);
    } catch (_) {
      checkScope();
      if (allowStale) {
        _failed.add(key);
        if (old != null) return old;
      }
      rethrow;
    }
  }

  void retry(CacheId id, String day) => _failed.remove((id, day));
}
