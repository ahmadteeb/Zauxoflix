import 'package:dio/dio.dart';

import '../db/app_database.dart';
import 'title_identity.dart';

typedef Json = Map<String, dynamic>;
typedef CatalogTitle = ({
  int source,
  CatalogKind kind,
  int id,
  String name,
  int? year,
  String? external,
});

class TraktTitle {
  const TraktTitle(
    this.id,
    this.name,
    this.year,
    this.imdb,
    this.tmdb, {
    this.language,
    this.genres = const [],
    this.releaseDate,
  });
  final String? language, releaseDate;
  final List<String> genres;
  final int id;
  final String name;
  final int? year;
  final String? imdb;
  final int? tmdb;
  Json toJson() => {
    'title': name,
    if (language != null) 'language': language,
    if (genres.isNotEmpty) 'genres': genres,
    if (releaseDate != null) 'released': releaseDate,
    'year': year,
    'ids': {'trakt': id, 'imdb': imdb, 'tmdb': tmdb},
  };
  static TraktTitle? parse(Object? value) {
    if (value is! Json || value['title'] is! String) return null;
    final ids = value['ids'];
    if (ids is! Json || ids['trakt'] is! int) return null;
    return TraktTitle(
      ids['trakt'] as int,
      value['title'] as String,
      value['year'] as int?,
      validImdb(ids['imdb']),
      ids['tmdb'] as int?,
      language: value['language'] is String
          ? value['language'] as String
          : null,
      genres: value['genres'] is List
          ? (value['genres'] as List).whereType<String>().toList()
          : const [],
      releaseDate: (value['released'] ?? value['first_aired'])?.toString(),
    );
  }

  bool hasExternal(String value) =>
      value == imdb || (tmdb != null && value == 'tmdb:$tmdb');
}

String? youtubeId(Object? url) {
  final uri = url is String ? Uri.tryParse(url) : null;
  if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) {
    return null;
  }
  final id = switch (uri.host.toLowerCase()) {
    'youtu.be' when uri.pathSegments.length == 1 => uri.pathSegments.first,
    'youtube.com' ||
    'www.youtube.com' ||
    'm.youtube.com' when uri.path == '/watch' => uri.queryParameters['v'],
    _ => null,
  };
  return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id) ? id : null;
}

class TitleDiscovery {
  const TitleDiscovery(
    this.title,
    this.rating,
    this.trailers,
    this.related, {
    this.complete = true,
  });
  final bool complete;
  final TraktTitle title;
  final double? rating;
  final Map<String, String> trailers;
  final List<TraktTitle> related;
  String? trailer(String language) =>
      trailers[language] ?? trailers['en'] ?? trailers.values.firstOrNull;
  Json toJson() => {
    'title': title.toJson(),
    'complete': complete,
    'rating': rating,
    'trailers': trailers,
    'related': related.map((r) => r.toJson()).toList(),
  };
  factory TitleDiscovery.fromJson(Json json) => TitleDiscovery(
    TraktTitle.parse(json['title'])!,
    (json['rating'] as num?)?.toDouble(),
    Map<String, String>.from(json['trailers'] as Map),
    [for (final row in json['related'] as List) ?TraktTitle.parse(row)],
    complete: json['complete'] != false,
  );
}

abstract interface class DiscoveryClient {
  Future<List<TraktTitle>> lookup(
    CatalogKind kind,
    String name,
    String? external,
  );
  Future<TitleDiscovery> details(CatalogKind kind, TraktTitle title);
}

typedef CastCredit = ({
  String id,
  String name,
  List<String> roles,
  String? photo,
});

List<CastCredit> parseCast(Object? payload) {
  if (payload is! Json || payload['cast'] is! List) return const [];
  final result = <String, CastCredit>{};
  for (final row in (payload['cast'] as List).whereType<Json>()) {
    final person = row['person'];
    if (person is! Json) continue;
    final ids = person['ids'];
    if (ids is! Json) continue;
    final id = ids['imdb'];
    final name = person['name'];
    if (id is! String ||
        !RegExp(r'^nm[0-9]{7,12}$').hasMatch(id) ||
        name is! String ||
        name.trim().isEmpty) {
      continue;
    }
    final roles = row['characters'];
    final images = person['images'];
    final heads = images is Json ? images['headshot'] : null;
    final photo = _traktImage(heads);
    result.putIfAbsent(
      id,
      () => (
        id: id,
        name: name,
        roles: roles is List ? roles.whereType<String>().toList() : <String>[],
        photo: photo,
      ),
    );
  }
  return result.values.toList();
}

abstract interface class CastClient {
  Future<List<CastCredit>> cast(CatalogKind kind, String titleId);
}

class ActingCredit {
  const ActingCredit(
    this.kind,
    this.name,
    this.year, {
    this.original,
    this.imdb,
    this.tmdb,
    this.trakt,
    this.poster,
  });
  final CatalogKind kind;
  final String name;
  final int? year;
  final String? original, imdb, poster;
  final int? tmdb, trakt;
  String get identity => imdb ?? (tmdb != null ? 'tmdb:$tmdb' : 'trakt:$trakt');
}

abstract interface class FilmographyClient {
  Future<String?> titlePoster(CatalogKind kind, String titleId);
  Future<List<ActingCredit>> actingCredits(String personId, CatalogKind kind);
}

String? _traktImage(Object? images) {
  if (images is! List) return null;
  for (final raw in images.whereType<String>()) {
    final url = Uri.tryParse(raw.contains('://') ? raw : 'https://$raw');
    if (url != null &&
        url.scheme == 'https' &&
        url.host.endsWith('.trakt.tv') &&
        url.userInfo.isEmpty &&
        !url.hasPort &&
        url.pathSegments.isNotEmpty) {
      return url.toString();
    }
  }
  return null;
}

class TraktClient implements DiscoveryClient, CastClient, FilmographyClient {
  TraktClient(String clientId)
    : dio = Dio(
        BaseOptions(
          baseUrl: 'https://api.trakt.tv',
          headers: {
            'trakt-api-key': clientId,
            'trakt-api-version': '2',
            'Content-Type': 'application/json',
          },
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 7),
        ),
      );
  final Dio dio;
  DateTime? _retryAfter;
  Future<Object?> _get(String path, [Map<String, dynamic>? params]) async {
    if (_retryAfter?.isAfter(DateTime.now()) == true) {
      throw StateError('Trakt requests are temporarily paused');
    }
    try {
      return (await dio.get<Object?>(path, queryParameters: params)).data;
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        final seconds =
            int.tryParse(error.response?.headers.value('retry-after') ?? '') ??
            60;
        _retryAfter = DateTime.now().add(Duration(seconds: seconds));
      } else if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        _retryAfter = DateTime.now().add(const Duration(seconds: 20));
      }
      rethrow;
    }
  }

  Future<List<Json>> dailyChart(CatalogKind kind) async {
    final series = kind == CatalogKind.series, type = series ? 'show' : 'movie';
    final rows = await _get('/${type}s/watched/daily', {
      'limit': 10,
      'extended': 'full',
    });
    if (rows is! List) throw const FormatException('Invalid Trakt chart');
    return [
      for (final row in rows.whereType<Json>())
        if (row[type] case final Json title)
          if (TraktTitle.parse(title) case final t?)
            {
              'name': t.name,
              'year': t.year,
              'imdb': t.imdb,
              'tmdb': t.tmdb,
              'art': title['images'] is Json
                  ? _traktImage((title['images'] as Json)['poster'])
                  : null,
              'url': Uri(
                scheme: 'https',
                host: 'trakt.tv',
                pathSegments: [
                  '${type}s',
                  ((title['ids'] as Json)['slug'] as String?) ??
                      t.id.toString(),
                ],
              ).toString(),
            },
    ];
  }

  Future<String?> spotlightImage(CatalogKind kind, String imdb) async {
    if (validImdb(imdb) == null) return null;
    final scope = kind == CatalogKind.series ? 'shows' : 'movies';
    final data = await _get('/$scope/$imdb', {'extended': 'full'});
    final images = data is Json ? data['images'] : null;
    return images is Json
        ? _traktImage(images['fanart']) ?? _traktImage(images['poster'])
        : null;
  }

  @override
  Future<String?> titlePoster(CatalogKind kind, String titleId) async {
    if (validImdb(titleId) == null && int.tryParse(titleId) == null) {
      return null;
    }
    final scope = kind == CatalogKind.series ? 'shows' : 'movies';
    final data = await _get('/$scope/$titleId', {'extended': 'full'});
    final images = data is Json ? data['images'] : null;
    return images is Json ? _traktImage(images['poster']) : null;
  }

  @override
  Future<List<ActingCredit>> actingCredits(
    String personId,
    CatalogKind kind,
  ) async {
    if (!RegExp(r'^nm[0-9]{7,12}$').hasMatch(personId)) return const [];
    final type = kind == CatalogKind.series ? 'show' : 'movie';
    final data = await _get('/people/$personId/${type}s', {'extended': 'full'});
    if (data is! Json || data['cast'] is! List) {
      throw const FormatException('Invalid acting credits');
    }
    final credits = <ActingCredit>[];
    for (final role in (data['cast'] as List).whereType<Json>()) {
      final work = role[type];
      final title = TraktTitle.parse(work);
      if (work is! Json || title == null) continue;
      final images = work['images'];
      credits.add(
        ActingCredit(
          kind,
          title.name,
          title.year,
          imdb: title.imdb,
          tmdb: title.tmdb,
          trakt: title.id,
          original: work['original_title'] as String?,
          poster: images is Json ? _traktImage(images['poster']) : null,
        ),
      );
    }
    return credits;
  }

  @override
  Future<List<CastCredit>> cast(CatalogKind kind, String titleId) async {
    final scope = kind == CatalogKind.series ? 'shows' : 'movies';
    return parseCast(
      await _get('/$scope/$titleId/people', {'extended': 'full'}),
    );
  }

  @override
  Future<List<TraktTitle>> lookup(
    CatalogKind kind,
    String name,
    String? external,
  ) async {
    final type = kind == CatalogKind.series ? 'show' : 'movie';
    final byTmdb = external?.startsWith('tmdb:') ?? false;
    final path = external == null
        ? '/search/$type'
        : byTmdb
        ? '/search/tmdb/${external.substring(5)}'
        : '/search/imdb/$external';
    final result = await _get(
      path,
      external == null
          ? {'query': name, 'limit': 100, 'extended': 'full'}
          : {'type': type, 'extended': 'full'},
    );
    return [
      for (final row in (result as List).whereType<Json>())
        if (row['type'] == type) ?TraktTitle.parse(row[type]),
    ];
  }

  @override
  Future<TitleDiscovery> details(CatalogKind kind, TraktTitle title) async {
    final path =
        '/${kind == CatalogKind.series ? 'shows' : 'movies'}/${title.id}';
    // A missing video response should not hide the rating or related titles.
    Future<Object?> optional(
      String suffix, [
      Map<String, dynamic>? params,
    ]) async {
      try {
        return await _get('$path/$suffix', params);
      } on Exception {
        return null;
      } on StateError {
        return null;
      }
    }

    final results = await Future.wait([
      optional('ratings'),
      optional('videos'),
      optional('related', {'limit': 12, 'extended': 'full'}),
    ]);
    final rating = results[0] as Json? ?? const <String, dynamic>{};
    final value = rating['rating'] as num?;
    final trailers = <String, String>{};
    for (final video in (results[1] as List? ?? const []).whereType<Json>()) {
      if (video['official'] != true ||
          (video['type'] as String?)?.toLowerCase() != 'trailer') {
        continue;
      }
      final id = youtubeId(video['url']);
      if (id != null) {
        trailers.putIfAbsent(
          (video['language'] as String? ?? '').toLowerCase(),
          () => id,
        );
      }
    }
    return TitleDiscovery(
      title,
      (rating['votes'] as num? ?? 0) > 0 &&
              value != null &&
              value >= 0 &&
              value <= 10
          ? value.toDouble()
          : null,
      trailers,
      [
        for (final row in (results[2] as List? ?? const []))
          ?TraktTitle.parse(row),
      ],
      complete: results.every((v) => v != null),
    );
  }
}
