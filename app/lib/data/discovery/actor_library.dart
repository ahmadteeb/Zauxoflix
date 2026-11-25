import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/media_item.dart';
import '../db/app_database.dart';
import '../providers.dart';
import 'discovery_repository.dart';
import 'imdb_index.dart';
import 'title_identity.dart';
import 'trakt_client.dart';

typedef ActorOrigin = ({
  int source,
  CatalogKind kind,
  int id,
  String? external,
});
typedef ActorQuery = ({String personId, ActorOrigin origin});

class ActorLibraryTitle extends MediaItem {
  const ActorLibraryTitle({
    required super.id,
    required super.title,
    required super.type,
    required super.subtitle,
    super.imageUrl,
    this.titleId,
    this.creditPoster,
  });
  final String? titleId;
  final String? creditPoster;
}

final actorTitlePosterProvider = FutureProvider.autoDispose
    .family<String?, (CatalogKind, String)>((ref, key) async {
      final client = ref.watch(discoveryClientProvider);
      if (client is! FilmographyClient) return null;
      final url = await (client as FilmographyClient).titlePoster(
        key.$1,
        key.$2,
      );
      if (ref.mounted) {
        final link = ref.keepAlive();
        final timer = Timer(const Duration(minutes: 30), link.close);
        ref.onDispose(timer.cancel);
      }
      return url;
    }, retry: (_, _) => null);

typedef ActorLibraryResult = ({
  List<ActorLibraryTitle> items,
  bool checking,
  bool incomplete,
});

final traktActingCreditsProvider = FutureProvider.autoDispose
    .family<List<ActingCredit>?, (String, CatalogKind)>((ref, key) async {
      final client = ref.watch(discoveryClientProvider);
      if (client is! FilmographyClient) return null;
      final result = await (client as FilmographyClient).actingCredits(
        key.$1,
        key.$2,
      );
      if (ref.mounted) {
        final link = ref.keepAlive();
        final expiry = Timer(const Duration(minutes: 30), link.close);
        ref.onDispose(expiry.cancel);
      }
      return result;
    }, retry: (_, _) => null);

final actorLibraryProvider = StreamProvider.autoDispose
    .family<ActorLibraryResult, ActorQuery>((ref, query) async* {
      final repo = ref.watch(discoveryRepositoryProvider);
      final (activeId, _) = ref.watch(
        activeSourceProvider.select((s) => (s.value?.id, s.value?.lastSyncAt)),
      );
      if (activeId != null && activeId != query.origin.source) {
        yield (
          items: const <ActorLibraryTitle>[],
          checking: false,
          incomplete: false,
        );
        return;
      }
      var incomplete = false;
      Future<List<ActingCredit>?> available(
        Future<List<ActingCredit>?> future,
      ) async {
        try {
          return await future;
        } catch (_) {
          incomplete = true;
          return null;
        }
      }

      final sources = await Future.wait([
        for (final kind in [CatalogKind.vod, CatalogKind.series])
          available(
            ref.watch(
              traktActingCreditsProvider((query.personId, kind)).future,
            ),
          ),
        available(ref.watch(imdbActingCreditsProvider(query.personId).future)),
      ]);
      if (!ref.mounted) return;
      final credits = sources.nonNulls.expand((s) => s).toList();
      if (credits.isEmpty) {
        yield (
          items: const <ActorLibraryTitle>[],
          checking: false,
          incomplete: incomplete || sources.every((s) => s == null),
        );
        return;
      }
      final matches = await _scanActorLibrary(repo.db, query.origin, credits);
      if (!ref.mounted) return;
      final pending = repo.client == null
          ? const <_Unconfirmed>[]
          : matches.unconfirmed
                .where(
                  (candidate) => candidate.credits.any((c) => !matches.has(c)),
                )
                .toList();
      yield (
        items: matches.items,
        checking: pending.isNotEmpty,
        incomplete: incomplete,
      );
      if (pending.isEmpty) return;
      // Only yearless, exact-name catalog candidates need an independent lookup.
      // Publish confident matches while the remaining identities are checked.
      for (final candidate in pending) {
        if (!ref.mounted) return;
        if (candidate.credits.every(matches.has)) continue;
        try {
          final verified = await repo.identify(candidate.key);
          if (verified == null) continue;
          for (final credit in candidate.credits) {
            if (credit.trakt == verified.id ||
                credit.imdb != null && credit.imdb == verified.imdb ||
                credit.tmdb != null && credit.tmdb == verified.tmdb) {
              matches.add(credit, candidate.key, candidate.art, 3);
              break;
            }
          }
        } catch (_) {
          incomplete = true;
          break;
        }
      }
      yield (items: matches.items, checking: false, incomplete: incomplete);
    }, retry: (_, _) => null);

typedef _Unconfirmed = ({
  CatalogTitle key,
  String? art,
  List<ActingCredit> credits,
});
typedef _Identity = (CatalogKind, String);

class _ActorLibraryMatches {
  _ActorLibraryMatches(this.origin);
  final ActorOrigin origin;
  final _found =
      <_Identity, ({int confidence, int year, ActorLibraryTitle item})>{};
  final _posters = <_Identity, String>{};
  final _excluded = <_Identity>{};
  final unconfirmed = <_Unconfirmed>[];
  bool has(ActingCredit c) =>
      _found.containsKey((c.kind, c.identity)) ||
      _excluded.contains((c.kind, c.identity));

  void add(
    ActingCredit credit,
    CatalogTitle key,
    String? artwork,
    int confidence,
  ) {
    final identity = (credit.kind, credit.identity);
    if (credit.kind == origin.kind &&
        (key.id == origin.id ||
            (origin.external != null &&
                (origin.external == credit.imdb ||
                    origin.external == 'tmdb:${credit.tmdb}' ||
                    origin.external == 'trakt:${credit.trakt}')))) {
      _excluded.add(identity);
      _found.remove(identity);
      return;
    }
    if (_excluded.contains(identity)) return;
    final series = key.kind == CatalogKind.series;
    final item = ActorLibraryTitle(
      titleId: credit.imdb ?? credit.trakt?.toString(),
      creditPoster: _posters[identity],
      id: key.id,
      title: key.name,
      type: series ? MediaType.series : MediaType.movie,
      imageUrl: artwork?.trim().isNotEmpty == true
          ? artwork
          : _posters[identity],
      subtitle: [
        series ? 'Series' : 'Movie',
        if (credit.year != null) credit.year,
      ].join(' · '),
    );
    final prior = _found[identity];
    if (prior != null &&
        (prior.confidence > confidence ||
            prior.confidence == confidence &&
                (prior.item.imageUrl != null || item.imageUrl == null))) {
      return;
    }
    _found[identity] = (
      confidence: confidence,
      year: credit.year ?? 0,
      item: item,
    );
  }

  List<ActorLibraryTitle> get items {
    final rows = _found.values.toList()
      ..sort((a, b) {
        final year = b.year.compareTo(a.year);
        return year != 0 ? year : a.item.title.compareTo(b.item.title);
      });
    final seen = <(MediaType?, int?)>{};
    return [
      for (final r in rows)
        if (seen.add((r.item.type, r.item.id))) r.item,
    ];
  }
}

final _bareYear = RegExp(r'^(.+) ((?:19|20)\d{2})$');
final _bilingualSeparator = RegExp(r'\s+(?:[-–—|/])\s+');
final _arabic = RegExp(r'[\u0600-\u06ff]');
String _fold(String name) => name
    .replaceAll('ı', 'i')
    .replaceAll('ş', 's')
    .replaceAll('ğ', 'g')
    .replaceAll('ç', 'c')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('i\u0307', 'i');

// Catalog scans and bilingual name normalization run away from the UI isolate.
Future<_ActorLibraryMatches> _scanActorLibrary(
  AppDatabase db,
  ActorOrigin origin,
  List<ActingCredit> credits,
) => db.computeWithDatabase(
  connect: AppDatabase.connect,
  computation: (db) => _scan(db, origin, credits),
);

Future<_ActorLibraryMatches> _scan(
  AppDatabase db,
  ActorOrigin origin,
  List<ActingCredit> credits,
) async {
  final result = _ActorLibraryMatches(origin);
  for (final kind in [CatalogKind.vod, CatalogKind.series]) {
    final scoped = credits.where((c) => c.kind == kind);
    if (scoped.isEmpty) continue;
    final byId = <String, ActingCredit>{};
    final byName = <String, List<ActingCredit>>{};
    for (final c in scoped) {
      for (final id in [
        c.imdb,
        if (c.tmdb != null) 'tmdb:${c.tmdb}',
        if (c.trakt != null) 'trakt:${c.trakt}',
      ].nonNulls) {
        byId.putIfAbsent(id, () => c);
      }
      for (final name in {c.name, c.original}.nonNulls) {
        byName.putIfAbsent(_fold(discoveryName(name)), () => []).add(c);
      }
      if (c.poster case final url?) result._posters[(kind, c.identity)] = url;
    }
    final series = kind == CatalogKind.series;
    final table = series ? 'series_items' : 'movies';
    final id = series ? 'series_id' : 'stream_id';
    final art = series ? 'cover' : 'icon';
    int? after;
    while (true) {
      final rows = await db
          .customSelect(
            """
        SELECT c.$id AS item,c.name,c.match_name,c.release_year,c.external_id,c.$art AS art,e.fingerprint,e.payload
        FROM $table c LEFT JOIN discovery_entries e ON e.source_id=c.source_id AND e.kind=?2 AND e.item_id=c.$id
        WHERE c.source_id=?1 ${after == null ? '' : 'AND c.$id>?3'} ORDER BY c.$id LIMIT 1200
      """,
            variables: [
              Variable.withInt(origin.source),
              Variable.withString(kind.name),
              if (after != null) Variable.withInt(after),
            ],
          )
          .get();
      for (final row in rows) {
        final localId = row.read<int>('item');
        final name = row.read<String>('name');
        final year = row.readNullable<int>('release_year');
        final external = row.readNullable<String>('external_id');
        final artUrl = row.readNullable<String>('art');
        final CatalogTitle key = (
          source: origin.source,
          kind: kind,
          id: localId,
          name: name,
          year: year,
          external: external,
        );
        final cached = _cachedIdentity(
          row.readNullable<String>('payload'),
          row.readNullable<String>('fingerprint'),
          name,
          year,
          external,
        );
        final known =
            byId[external] ??
            (cached == null
                ? null
                : byId[cached.imdb] ??
                      byId['tmdb:${cached.tmdb}'] ??
                      byId['trakt:${cached.id}']);
        if (known != null) {
          result.add(known, key, artUrl, 4);
          continue;
        }
        if (external != null || cached != null) continue;
        final aliases = {_fold(row.read<String>('match_name'))};
        if (_arabic.hasMatch(name)) {
          final parts = name.split(_bilingualSeparator);
          if (parts.length > 1 && parts.any((p) => !_arabic.hasMatch(p))) {
            aliases.addAll(parts.map((p) => _fold(discoveryName(p))));
          }
        }
        final dated = <String, ActingCredit>{};
        final undated = <String, ActingCredit>{};
        for (final alias in aliases) {
          for (final c in byName[alias] ?? const <ActingCredit>[]) {
            if (year != null && c.year == year) {
              dated.putIfAbsent(c.identity, () => c);
            }
            if (year == null) undated.putIfAbsent(c.identity, () => c);
          }
          final suffix = _bareYear.firstMatch(alias);
          if (suffix == null) continue;
          final suffixYear = int.parse(suffix[2]!);
          if (year != null && year != suffixYear) continue;
          for (final c in byName[suffix[1]] ?? const <ActingCredit>[]) {
            if (c.year == suffixYear) dated.putIfAbsent(c.identity, () => c);
          }
        }
        if (dated.length == 1) {
          final c = dated.values.single;
          result.add(c, key, artUrl, 2);
        } else if (dated.isEmpty &&
            undated.isNotEmpty &&
            !(localId == origin.id && kind == origin.kind)) {
          result.unconfirmed.add((
            key: key,
            art: artUrl,
            credits: undated.values.toList(),
          ));
        }
      }
      if (rows.length < 1200) break;
      after = rows.last.read<int>('item');
    }
  }
  return result;
}

TraktTitle? _cachedIdentity(
  String? payload,
  String? fingerprint,
  String name,
  int? year,
  String? external,
) {
  if (payload == null || fingerprint == null) return null;
  try {
    final stored = jsonDecode(fingerprint);
    if (stored is! List ||
        stored.length != 3 ||
        stored[0] != name ||
        year != null && stored[1] != null && stored[1] != year ||
        external != null && stored[2] != null && stored[2] != external) {
      return null;
    }
    final data = jsonDecode(payload);
    final cached = data is Json ? TraktTitle.parse(data['title']) : null;
    return external == null || cached?.hasExternal(external) == true
        ? cached
        : null;
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}
