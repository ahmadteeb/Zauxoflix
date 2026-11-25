import 'dart:math' as math;
import '../../core/models/media_item.dart';
import '../db/app_database.dart';
import 'home_catalog.dart';
import 'trakt_client.dart';

enum HomeSignal { saved, watching, watched }

typedef HomeActivity = ({
  HomeId key,
  HomeSignal signal,
  int stamp,
  double progress,
});
typedef HomeFeed = ({
  List<HomePick> movies,
  List<HomePick> series,
  List<HomePick> featured,
});
const emptyHomeFeed = (
  movies: <HomePick>[],
  series: <HomePick>[],
  featured: <HomePick>[],
);

class HomePick extends MediaItem {
  HomePick(
    this.work,
    this.score,
    this.reason,
    this.genres,
    this.categoryKey, [
    this.becauseOf,
  ]) : super(
         id: work.id,
         title: work.name,
         type: work.kind == CatalogKind.series
             ? MediaType.series
             : MediaType.movie,
         imageUrl: work.art,
         badge: [
           if (work.imdb?.score case final r?) 'IMDb ${r.toStringAsFixed(1)}',
           ?work.year,
         ].join(' · '),
         subtitle: reason,
       );
  final (HomeId, HomeSignal)? becauseOf;
  final LibraryWork work;
  final double score;
  final String reason, categoryKey;
  final Set<String> genres;
  bool get highlyRated =>
      (work.imdb?.votes ?? 0) >= 1000 && (work.imdb?.score ?? 0) >= 7.3;
}

final _languagePatterns = <String, RegExp>{
  for (final e in {
    'en': r'\benglish\b|\[en\]',
    'ar': r'\barabic\b|\[ar\]|عربي|عربية|مصري|سوري|خليجي|لبناني',
    'tr': r'\bturkish\b|تركي',
    'fr': r'\bfrench\b|فرنسي',
    'ko': r'\bkorean\b|كوري',
    'hi': r'\bhindi\b|هندي',
    'es': r'\bspanish\b|اسباني|إسباني',
    'ja': r'\bjapanese\b|ياباني',
    'de': r'\bgerman\b|ألماني',
    'it': r'\bitalian\b|إيطالي',
    'ru': r'\brussian\b|روسي',
  }.entries)
    e.key: RegExp(e.value, caseSensitive: false),
};
const _genreNames = {
  'action',
  'adventure',
  'animation',
  'comedy',
  'crime',
  'documentary',
  'drama',
  'family',
  'fantasy',
  'history',
  'horror',
  'music',
  'mystery',
  'romance',
  'sci-fi',
  'sport',
  'thriller',
  'war',
  'western',
};
String _genre(String g) => switch (g.toLowerCase()) {
  'science-fiction' || 'sci' => 'sci-fi',
  final v => v,
};
final _dub = RegExp(r'مدبلج|\bdubbed\b', caseSensitive: false);

class _Category {
  _Category(String label) : name = label.trim().toLowerCase() {
    final first = _genre(name.split('|').first.trim());
    genre = _genreNames.contains(first) ? first : null;
    // Subtitle language describes captions, not the language of the title.
    language = name.contains('subtitle')
        ? null
        : _languagePatterns.entries
              .where((e) => e.value.hasMatch(name))
              .firstOrNull
              ?.key;
  }
  final String name;
  late final String? genre, language;
}

typedef _FeatureEvidence = ({
  double total,
  double strongest,
  String reason,
  (HomeId, HomeSignal) origin,
});

class _Taste {
  final features = <String, _FeatureEvidence>{};
  void add(
    String key,
    double weight,
    String reason,
    (HomeId, HomeSignal) origin,
  ) {
    final prior = features[key];
    features[key] = (
      total: (prior?.total ?? 0) + weight,
      origin: prior != null && prior.strongest >= weight
          ? prior.origin
          : origin,
      strongest: math.max(prior?.strongest ?? 0, weight),
      reason: prior != null && prior.strongest >= weight
          ? prior.reason
          : reason,
    );
  }
}

double _quality(HomeRating? imdb) {
  final rating = imdb?.score;
  if (imdb == null || rating == null) return 6.5;
  return (rating * imdb.votes + 6.5 * 1500) / (imdb.votes + 1500);
}

HomeFeed rankHome(
  List<LibraryWork> library,
  List<HomeActivity> activity,
  Map<HomeId, TitleDiscovery> extras,
  DateTime now, {
  int? daySeed,
  Map<String, int> recentFeatures = const {},
  int limit = 24,
}) {
  if (library.isEmpty) return emptyHomeFeed;
  final random = math.Random(daySeed ?? 0);
  final byKey = {for (final w in library) w.key: w};
  final categories = <String, _Category>{};
  final profile = _Taste();
  final excluded = <(CatalogKind, String)>{};
  final localIds = {for (final a in activity) a.key};
  final extraById = <(CatalogKind, String), TraktTitle>{},
      extraByName = <(CatalogKind, String, int?), TraktTitle?>{};
  void index(CatalogKind k, TraktTitle t) {
    if (t.imdb != null) extraById[(k, t.imdb!)] = t;
    if (t.tmdb != null) extraById[(k, 'tmdb:${t.tmdb}')] = t;
    final key = (k, t.name.toLowerCase(), t.year);
    if (!extraByName.containsKey(key) || extraByName[key]?.id == t.id) {
      extraByName[key] = t;
    } else {
      extraByName[key] = null;
    }
  }

  for (final e in extras.entries) {
    index(e.key.$1, e.value.title);
    for (final related in e.value.related) {
      index(e.key.$1, related);
    }
  }
  TraktTitle? remote(LibraryWork w) {
    final known =
        extras[w.key]?.title ??
        w.cached ??
        extraById[(w.kind, w.imdbId ?? w.external ?? '')];
    if (known != null ||
        w.external != null ||
        w.imdbId != null ||
        w.year == null) {
      return known;
    }
    for (final alias in w.names) {
      final match = extraByName[(w.kind, alias, w.year)];
      if (match != null) return match;
    }
    return null;
  }

  final seenSignals = <(HomeId, HomeSignal)>{};
  final signalCounts = <HomeSignal, int>{};
  // Feature weights are shared across movies and series. Keys for provider
  // categories and Trakt related titles retain their catalog kind.
  Map<String, double> traits(
    LibraryWork w,
    _Category c,
    TraktTitle? t,
    Set<String> genres,
  ) {
    final lang = t?.language ?? c.language, year = w.year ?? t?.year;
    return {
      for (final g in genres) 'genre/$g': 3.0 / math.sqrt(genres.length),
      if (c.name.isNotEmpty) 'category/${w.kind.name}/${c.name}': 2.4,
      if (lang != null && lang.isNotEmpty) 'language/$lang': 2.2,
      if (_dub.hasMatch(w.name) || _dub.hasMatch(c.name)) 'dubbed': 1.4,
      if (year != null) 'era/${year ~/ 5}': 1.35,
      if (year != null) 'era/${year ~/ 5 - 1}': .38,
      if (year != null) 'era/${year ~/ 5 + 1}': .38,
    };
  }

  Set<String> genresOf(LibraryWork w, _Category c, TraktTitle? t) => {
    ...?w.imdb?.genres,
    ...?t?.genres.map(_genre),
    ?c.genre,
  };
  for (final a in activity) {
    final w = byKey[a.key];
    if (w == null) continue;
    excluded.add((w.kind, w.identity));
    final t = remote(w);
    if (t?.imdb case final id?) excluded.add((w.kind, id));
    if (!seenSignals.add((w.key, a.signal)) ||
        (signalCounts[a.signal] ?? 0) >= 50) {
      continue;
    }
    signalCounts.update(a.signal, (v) => v + 1, ifAbsent: () => 1);
    final days = math.max(
      0,
      now.millisecondsSinceEpoch / 86400000 - a.stamp / 86400,
    );
    final recency = .2 + .8 * math.pow(.5, days / 120);
    final weight =
        recency *
        switch (a.signal) {
          HomeSignal.saved => 2.0,
          HomeSignal.watched => 3.2,
          HomeSignal.watching => .25 + 2.4 * math.sqrt(a.progress.clamp(0, 1)),
        };
    final reason = switch (a.signal) {
      HomeSignal.saved => 'Because you saved ${w.name}',
      HomeSignal.watching => 'Because you’re watching ${w.name}',
      HomeSignal.watched => 'Because you watched ${w.name}',
    };
    final c = categories.putIfAbsent(w.category, () => _Category(w.category));
    for (final e in traits(w, c, t, genresOf(w, c, t)).entries) {
      profile.add(e.key, weight * e.value, reason, (w.key, a.signal));
    }
    int place = 0;
    for (final r in extras[a.key]?.related ?? const <TraktTitle>[]) {
      profile.add(
        'related/${w.kind.name}/${r.id}',
        weight * 6 / (1 + place++ * .1),
        reason,
        (w.key, a.signal),
      );
    }
  }
  final best = <(CatalogKind, String), HomePick>{};
  for (final w in library) {
    if (localIds.contains(w.key) || excluded.contains((w.kind, w.identity))) {
      continue;
    }
    final t = remote(w);
    if (t?.imdb != null && excluded.contains((w.kind, t!.imdb!))) continue;
    final release = DateTime.tryParse(t?.releaseDate ?? '');
    if ((w.year ?? 0) > now.year || release != null && release.isAfter(now)) {
      continue;
    }
    final c = categories.putIfAbsent(w.category, () => _Category(w.category));
    final genres = genresOf(w, c, t);
    final features = traits(w, c, t, genres);
    if (t != null) features['related/${w.kind.name}/${t.id}'] = 3.2;
    var affinity = 0.0, biggest = 0.0;
    String? reason;
    (HomeId, HomeSignal)? origin;
    for (final e in features.entries) {
      final evidence = profile.features[e.key];
      if (evidence == null) continue;
      final points = e.value * math.log(1 + evidence.total);
      affinity += points;
      if (points > biggest) {
        biggest = points;
        reason = evidence.reason;
        origin = evidence.origin;
      }
    }
    final quality = _quality(w.imdb), year = w.year ?? t?.year;
    final freshness = year == null
        ? 0.0
        : 1.0 / (1 + (now.year - year).abs() / 8);
    final score =
        affinity +
        (daySeed == null ? 0 : random.nextDouble() * .9) +
        2.2 * (quality - 6.5) +
        .3 * ((w.providerScore ?? 6.5) - 6.5) +
        freshness * .65 +
        (w.art?.isNotEmpty == true ? 0.25 : 0);
    final pick = HomePick(
      w,
      score,
      reason ?? (w.imdb?.score != null ? 'Rated on IMDb' : 'From your library'),
      genres,
      c.name,
      origin,
    );
    final id = (w.kind, t?.imdb ?? w.identity);
    if (best[id] == null || best[id]!.score < score) best[id] = pick;
  }
  List<HomePick> diverse(CatalogKind kind) {
    final pool = best.values.where((p) => p.work.kind == kind).toList()
      ..sort((a, b) {
        final cmp = b.score.compareTo(a.score);
        return cmp == 0 ? a.work.id.compareTo(b.work.id) : cmp;
      });
    final short = pool.take(160).toList(), selected = <HomePick>[];
    final exposure = <String, int>{};
    double adjusted(HomePick p) =>
        p.score -
        (exposure[p.categoryKey] ?? 0) * .55 -
        p.genres.fold<double>(
              0,
              (sum, g) => sum + (exposure['g/$g'] ?? 0) * .24,
            ) /
            math.max(1, p.genres.length);
    while (short.isNotEmpty && selected.length < limit) {
      var index = 0, high = adjusted(short.first);
      for (var i = 1; i < short.length; i++) {
        final value = adjusted(short[i]);
        if (value > high) {
          index = i;
          high = value;
        }
      }
      final p = short.removeAt(index);
      selected.add(p);
      for (final k in [
        if (p.categoryKey.isNotEmpty) p.categoryKey,
        ...p.genres.map((g) => 'g/$g'),
      ]) {
        exposure.update(k, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    return selected;
  }

  final movies = diverse(CatalogKind.vod), series = diverse(CatalogKind.series);
  final rated = best.values.where((p) => p.highlyRated).toList()
    ..sort((a, b) {
      final quality = _quality(b.work.imdb).compareTo(_quality(a.work.imdb));
      return quality == 0 ? a.work.id.compareTo(b.work.id) : quality;
    });
  if (daySeed != null) {
    final featured = <HomePick>[], used = <HomeId>{};
    // Cycle within strong candidates. Yesterday's picks yield to unseen
    // candidates, and a small library falls back to the least recent pick.
    void choose(Iterable<HomePick> candidates, {bool imdb = false}) {
      final pool = candidates.where((p) => !used.contains(p.work.key)).toList();
      if (pool.isEmpty) return;
      int exposure(HomePick p) =>
          recentFeatures['${p.work.kind.name}/${p.work.identity}'] ?? 0;
      final oldest = pool.map(exposure).reduce(math.min);
      final fresh = pool.where((p) => exposure(p) == oldest).toList();
      final pick = fresh[random.nextInt(math.min(fresh.length, 5))];
      used.add(pick.work.key);
      featured.add(
        imdb
            ? HomePick(
                pick.work,
                pick.score,
                'Highly rated on IMDb',
                pick.genres,
                pick.categoryKey,
              )
            : pick,
      );
    }

    final firstMovie =
        series.isEmpty ||
        movies.isNotEmpty && movies.first.score >= series.first.score;
    final primary = firstMovie ? movies : series,
        secondary = firstMovie ? series : movies;
    choose(primary.take(15));
    choose(
      rated
          .where(
            (p) =>
                p.work.kind ==
                (firstMovie ? CatalogKind.series : CatalogKind.vod),
          )
          .take(30),
      imdb: true,
    );
    choose(secondary.take(15));
    choose(
      rated
          .where(
            (p) =>
                p.work.kind ==
                (firstMovie ? CatalogKind.vod : CatalogKind.series),
          )
          .take(30),
      imdb: true,
    );
    while (featured.length < 6) {
      final before = featured.length;
      choose(movies.take(24));
      if (featured.length < 6) choose(series.take(24));
      if (featured.length == before) break;
    }
    return (movies: movies, series: series, featured: featured);
  }
  final featured = <HomePick>[];
  final all = [?movies.firstOrNull, ?series.firstOrNull]
    ..sort((a, b) => b.score.compareTo(a.score));
  final featuredKeys = <HomeId>{};
  void add(HomePick? p, {bool imdb = false}) {
    if (p == null || !featuredKeys.add(p.work.key)) return;
    featured.add(
      imdb
          ? HomePick(
              p.work,
              p.score,
              'Highly rated on IMDb',
              p.genres,
              p.categoryKey,
            )
          : p,
    );
  }

  add(all.firstOrNull);
  add(rated.firstOrNull, imdb: true);
  for (final p in all) {
    add(p);
  }
  for (final kind in [CatalogKind.vod, CatalogKind.series]) {
    add(rated.where((p) => p.work.kind == kind).firstOrNull, imdb: true);
  }
  for (var i = 0; i < 3; i++) {
    if (i < movies.length) add(movies[i]);
    if (i < series.length) add(series[i]);
  }
  return (movies: movies, series: series, featured: featured.take(6).toList());
}
