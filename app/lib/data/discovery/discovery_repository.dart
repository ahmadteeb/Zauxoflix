import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Variable, BooleanExpressionOperators;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'title_identity.dart';
import 'daily_cache.dart';
import 'home_snapshot.dart' show homeCatalogNames;
import 'trakt_client.dart';

final discoveryClientProvider = Provider<DiscoveryClient?>((ref) {
  const key = String.fromEnvironment('TRAKT_CLIENT_ID');
  if (key.isEmpty) return null;
  final client = TraktClient(key);
  ref.onDispose(() => client.dio.close());
  return client;
});
final discoveryRepositoryProvider = Provider(
  (ref) => DiscoveryRepository(
    ref.watch(databaseProvider),
    ref.watch(discoveryClientProvider),
  ),
);
final titleDiscoveryProvider = FutureProvider.autoDispose
    .family<TitleDiscovery?, CatalogTitle>(
      (ref, key) => ref.watch(discoveryRepositoryProvider).load(key),
    );
final relatedTitlesProvider = FutureProvider.autoDispose
    .family<List<MediaItem>, CatalogTitle>((ref, key) async {
      ref.watch(activeSourceProvider.select((v) => v.value?.lastSyncAt));
      final repo = ref.watch(discoveryRepositoryProvider);
      final cache = ref.watch(dailyCacheProvider),
          day = ref.watch(recommendationDayProvider);
      final snapshot = await cache.get(
        (
          source: key.source,
          slot:
              'related.v1/${key.kind.name}/${key.id}/${repo.client != null}/${jsonEncode([key.name, key.year, key.external])}',
        ),
        day,
        (_) async {
          final details = await repo.load(key);
          final items = await repo.recommendations(key, details);
          return {
            'items': [
              for (final i in items) [i.id, i.title, i.imageUrl],
            ],
          };
        },
      );
      final rows = (snapshot.data['items'] as List).cast<List<Object?>>();
      final names = await homeCatalogNames(
        repo.db,
        key.source,
        rows.map((r) => (key.kind, r[0] as int)),
      );
      return [
        for (final r in rows)
          if (names[(key.kind, r[0])] == r[1])
            MediaItem(
              id: r[0] as int,
              title: r[1] as String,
              imageUrl: r[2] as String?,
              type: key.kind == CatalogKind.series
                  ? MediaType.series
                  : MediaType.movie,
            ),
      ];
    });

final castCreditsProvider = FutureProvider.autoDispose
    .family<List<CastCredit>, (CatalogKind, String)>((ref, key) async {
      final client = ref.watch(discoveryClientProvider);
      if (client is! CastClient) return const [];
      final credits = await (client as CastClient).cast(key.$1, key.$2);
      if (ref.mounted) {
        final link = ref.keepAlive();
        final expiry = Timer(const Duration(hours: 1), link.close);
        ref.onDispose(expiry.cancel);
      }
      return credits;
    });

CatalogTitle movieKey(Movie m, {int? year, String? external}) => (
  source: m.sourceId,
  kind: CatalogKind.vod,
  id: m.streamId,
  name: m.name,
  year: year ?? m.releaseYear,
  external: external ?? m.externalId,
);
CatalogTitle seriesKey(SeriesItem s, {int? year, String? external}) => (
  source: s.sourceId,
  kind: CatalogKind.series,
  id: s.seriesId,
  name: s.name,
  year: year ?? s.releaseYear,
  external: external ?? s.externalId,
);
String? providerRating(double? score, int? scale) => score == null || score <= 0
    ? null
    : 'Provider ${score.toStringAsFixed(1)}${scale == null ? '' : '/$scale'}';

class DiscoveryRepository {
  DiscoveryRepository(this.db, this.client);
  final AppDatabase db;
  final DiscoveryClient? client;
  final _pending = <CatalogTitle, Future<TitleDiscovery?>>{};
  Future<TitleDiscovery?> load(CatalogTitle key) => _pending.putIfAbsent(
    key,
    () => _load(key).whenComplete(() {
      _pending.remove(key);
    }),
  );

  String _fingerprint(CatalogTitle key) =>
      jsonEncode([key.name, key.year, key.external]);
  Future<DiscoveryEntry?> _entry(CatalogTitle key) =>
      (db.select(db.discoveryEntries)..where(
            (e) =>
                e.sourceId.equals(key.source) &
                e.kind.equalsValue(key.kind) &
                e.itemId.equals(key.id) &
                e.fingerprint.equals(_fingerprint(key)),
          ))
          .getSingleOrNull();

  Future<TraktTitle?> _resolve(CatalogTitle key) async {
    final parts = splitTitle(key.name);
    final year = key.year ?? parts.year;
    if (key.external == null &&
        (parts.name.isEmpty || parts.name.contains('://'))) {
      return null;
    }
    final list = await client!.lookup(key.kind, parts.name, key.external);
    final matches = list.where(
      (t) => key.external != null
          ? t.hasExternal(key.external!)
          : discoveryName(t.name) == discoveryName(parts.name) &&
                (year == null || t.year == year),
    );
    final unique = {for (final t in matches) t.id: t};
    if (unique.isNotEmpty || key.external != null) {
      return unique.length == 1 ? unique.values.single : null;
    }
    // Some providers append a bare release year. Prefer the literal title
    // first so numeric names such as Blade Runner 2049 retain their identity.
    final suffix = RegExp(r'^(.+) ((?:19|20)\d{2})$').firstMatch(parts.name);
    if (suffix == null) return null;
    final bareYear = int.parse(suffix[2]!);
    if (year != null && year != bareYear) return null;
    final bare = suffix[1]!;
    final retry = await client!.lookup(key.kind, bare, null);
    final verified = {
      for (final t in retry)
        if (t.year == bareYear && discoveryName(t.name) == discoveryName(bare))
          t.id: t,
    };
    return verified.length == 1 ? verified.values.single : null;
  }

  Future<void> _save(CatalogTitle key, TitleDiscovery? data) async {
    await db
        .into(db.discoveryEntries)
        .insertOnConflictUpdate(
          DiscoveryEntriesCompanion.insert(
            sourceId: key.source,
            kind: key.kind,
            itemId: key.id,
            fingerprint: _fingerprint(key),
            payload: jsonEncode(data?.toJson()),
            fetchedAt: DateTime.now(),
          ),
        );
  }

  Future<TraktTitle?> identify(CatalogTitle key) async {
    final cached = await _entry(key);
    if (cached != null) {
      final json = jsonDecode(cached.payload) as Json?;
      if (json != null) return TraktTitle.parse(json['title']);
      if (DateTime.now().difference(cached.fetchedAt) <
          const Duration(hours: 24)) {
        return null;
      }
    }
    if (client == null) return null;
    final match = await _resolve(key);
    await db.transaction(() async {
      // A concurrent details request may already have saved the full response.
      if ((await _entry(key))?.payload != cached?.payload) return;
      await _save(
        key,
        match == null
            ? null
            : TitleDiscovery(match, null, const {}, const [], complete: false),
      );
    });
    return match;
  }

  Future<TitleDiscovery?> _load(CatalogTitle key) async {
    if (client == null) return null;
    final cached = await _entry(key);
    final payload = cached == null ? null : jsonDecode(cached.payload) as Json?;
    final stale = payload == null ? null : TitleDiscovery.fromJson(payload);
    if (cached != null &&
        stale?.complete != false &&
        DateTime.now().difference(cached.fetchedAt) <
            const Duration(hours: 24)) {
      return stale;
    }
    try {
      final match = stale?.title ?? await _resolve(key);
      final data = match == null
          ? null
          : await client!.details(key.kind, match);
      if (data != null && !data.complete) {
        return TitleDiscovery(
          data.title,
          data.rating ?? stale?.rating,
          data.trailers.isEmpty ? stale?.trailers ?? const {} : data.trailers,
          data.related.isEmpty ? stale?.related ?? const [] : data.related,
          complete: false,
        );
      }
      await _save(key, data);
      return data;
    } catch (_) {
      return stale;
    }
  }

  /// Prefer verified Trakt matches. A named playlist category also works
  /// offline and for localized titles that cannot be identified on Trakt.
  Future<List<MediaItem>> recommendations(
    CatalogTitle seed,
    TitleDiscovery? details, {
    Set<int> excluded = const {},
  }) async {
    final remote = details == null
        ? <MediaItem>[]
        : await playable(seed, details);
    final eligible = remote
        .where((item) => !excluded.contains(item.id))
        .toList();
    if (eligible.isNotEmpty) return eligible;
    final series = seed.kind == CatalogKind.series;
    final table = series ? 'series_items' : 'movies';
    final id = series ? 'series_id' : 'stream_id';
    final art = series ? 'cover' : 'icon';
    final added = series ? 'last_modified_at' : 'added_at';
    final rows = await db
        .customSelect(
          """
      SELECT c.$id AS item, c.name, c.$art AS art
      FROM $table seed JOIN categories cat ON cat.source_id=seed.source_id
        AND cat.category_id=seed.category_id AND cat.kind=?3
      JOIN $table c ON c.source_id=seed.source_id AND c.category_id=seed.category_id
      WHERE seed.source_id=?1 AND seed.$id=?2 AND c.$id<>seed.$id
        AND lower(trim(cat.name)) NOT IN ('', 'all', 'all movies', 'all series', 'movies', 'series', 'uncategorized')
      ORDER BY CASE WHEN c.rating_scale > 0 THEN c.rating/c.rating_scale END DESC,
        c.$added DESC, c.$id DESC LIMIT 96
    """,
          variables: [
            Variable.withInt(seed.source),
            Variable.withInt(seed.id),
            Variable.withString(seed.kind.name),
          ],
        )
        .get();
    final seen = {discoveryName(seed.name)};
    final matches = <MediaItem>[];
    for (final row in rows) {
      final item = row.read<int>('item');
      final name = row.read<String>('name');
      if (excluded.contains(item) || !seen.add(discoveryName(name))) continue;
      matches.add(
        MediaItem(
          id: item,
          title: name,
          imageUrl: row.readNullable<String>('art'),
          type: series ? MediaType.series : MediaType.movie,
        ),
      );
      if (matches.length == 30) break;
    }
    return matches;
  }

  /// Match against indexed local entries, including titles that have never
  /// been opened. A yearless candidate needs independent identity confirmation.
  Future<List<MediaItem>> playable(
    CatalogTitle seed,
    TitleDiscovery details,
  ) async {
    final series = seed.kind == CatalogKind.series;
    final table = series ? 'series_items' : 'movies';
    final id = series ? 'series_id' : 'stream_id';
    final image = series ? 'cover' : 'icon';
    final result = <int, MediaItem>{};
    for (final remote in details.related) {
      if (remote.id == details.title.id) continue;
      final rows = await db
          .customSelect(
            'SELECT $id AS item, name, $image AS art, external_id, release_year FROM $table WHERE source_id=?1 '
            'AND (match_name IN (?2,?5) OR external_id IN (?3,?4)) ORDER BY $id LIMIT 16',
            variables: [
              Variable.withInt(seed.source),
              Variable.withString(discoveryName(remote.name)),
              Variable.withString(remote.imdb ?? ''),
              Variable.withString(
                remote.tmdb == null ? '' : 'tmdb:${remote.tmdb}',
              ),
              Variable.withString(
                remote.year == null
                    ? discoveryName(remote.name)
                    : discoveryName('${remote.name} ${remote.year}'),
              ),
            ],
          )
          .get();
      for (final row in rows) {
        final localId = row.read<int>('item');
        if (localId == seed.id) continue;
        final ext = row.readNullable<String>('external_id');
        final year = row.readNullable<int>('release_year');
        if (ext != null && !remote.hasExternal(ext)) continue;
        if (ext == null && year != null && remote.year != year) continue;
        final name = row.read<String>('name');
        final datedName =
            remote.year != null &&
            discoveryName(name) ==
                discoveryName('${remote.name} ${remote.year}');
        if (ext == null && year == null && !datedName) {
          final key = (
            source: seed.source,
            kind: seed.kind,
            id: localId,
            name: name,
            year: year,
            external: ext,
          );
          try {
            if ((await identify(key))?.id != remote.id) continue;
          } catch (_) {
            continue;
          }
        }
        result[localId] = MediaItem(
          title: name,
          id: localId,
          imageUrl: row.readNullable<String>('art'),
          type: series ? MediaType.series : MediaType.movie,
        );
        break;
      }
    }
    return result.values.toList();
  }
}
