import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../epg/xmltv_parser.dart';
import '../live/live_directory.dart';
import '../m3u/m3u_parser.dart';
import '../xtream/xtream_api.dart';
import '../xtream/xtream_models.dart';

Future<LiveDirectory> _groupForGuide(List<LiveChannel> rows) =>
    Isolate.run(() => buildLiveDirectory(rows, const []));

/// Only validators from a successfully published catalog may be sent back.
class _FeedCache {
  _FeedCache(this.sourceId, List<CatalogValidator> saved)
    : saved = {for (final row in saved) row.feed: row};
  final int sourceId;
  final Map<CatalogFeed, CatalogValidator> saved;
  final refreshed = <CatalogFeed, CatalogValidatorsCompanion>{};

  Map<String, String> headers(CatalogFeed feed) => {
    'If-None-Match': ?saved[feed]?.etag,
    'If-Modified-Since': ?saved[feed]?.lastModified,
  };

  bool changed(CatalogFeed feed, Response<Object?> response) {
    if (response.statusCode == 304) return false;
    refreshed[feed] = CatalogValidatorsCompanion.insert(
      sourceId: sourceId,
      feed: feed,
      etag: Value(response.headers.value('etag')),
      lastModified: Value(response.headers.value('last-modified')),
    );
    return true;
  }
}

/// Full catalog refresh for one source. Payloads are parsed in background
/// isolates (playlists can be 10k+ rows on 1GB-RAM boxes) and published
/// together after every required feed succeeds. EPG (XMLTV) is downloaded to a temp
/// file and stream-parsed so it never has to fit in memory.
class CatalogSyncService {
  CatalogSyncService(this._db);

  final AppDatabase _db;

  static const epgLookback = Duration(hours: 3);
  static const epgHorizon = Duration(days: 3);

  Future<void> syncAll(
    Source source, {
    void Function(String stage)? onStage,
    void Function()? onCatalogReady,
  }) async {
    final dir = await Directory.systemTemp.createTemp('zauxoflix_import');
    final file = File('${dir.path}/catalog.sqlite');
    final stage = CatalogStagingDatabase(file);
    try {
      // The staging DB only needs the local foreign key.
      await stage.insertSource(
        SourcesCompanion.insert(
          id: Value(source.id),
          name: '',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final current = await (_db.select(
        _db.sources,
      )..where((s) => s.id.equals(source.id))).getSingle();
      final saved = await (_db.select(
        _db.catalogValidators,
      )..where((v) => v.sourceId.equals(source.id))).get();
      final cache = _FeedCache(
        source.id,
        current.lastSyncAt == null ? [] : saved,
      );
      String? discoveredGuide = current.discoveredEpgUrl;
      switch (source.sourceType) {
        case SourceType.xtream:
          await _syncXtream(stage, source, cache, onStage);
        case SourceType.m3u:
          discoveredGuide = await _syncM3u(
            stage,
            source,
            cache,
            current.discoveredEpgUrl,
            onStage,
          );
      }
      await _db.publishImport(
        file,
        source,
        refreshedFeeds: cache.refreshed,
        discoveredGuide: discoveredGuide,
      );
      onCatalogReady?.call();
      try {
        await _syncEpg(stage, file, source, discoveredGuide, onStage);
      } catch (e) {
        debugPrint(
          'EPG sync failed for source ${source.id}: ${syncErrorMessage(e)}',
        );
      }
    } finally {
      await stage.close();
      await _deleteQuietly(file);
    }
  }

  // --- Xtream ---

  Future<void> _syncXtream(
    AppDatabase stage,
    Source source,
    _FeedCache cache,
    void Function(String stage)? onStage,
  ) async {
    final api = XtreamApi(
      XtreamCredentials(
        serverUrl: source.serverUrl,
        username: source.username,
        password: source.password,
      ),
    );

    Future<String?> body(CatalogFeed feed, String action) async {
      final response = await api.fetch(
        action: action,
        validators: cache.headers(feed),
      );
      return cache.changed(feed, response) ? response.data! : null;
    }

    onStage?.call('Loading categories…');
    for (final (kind, feed, action) in [
      (CatalogKind.live, CatalogFeed.liveCategories, 'get_live_categories'),
      (CatalogKind.vod, CatalogFeed.movieCategories, 'get_vod_categories'),
      (
        CatalogKind.series,
        CatalogFeed.seriesCategories,
        'get_series_categories',
      ),
    ]) {
      final contents = await body(feed, action);
      if (contents == null) continue;
      final parsed = await compute(parseCategories, contents);
      await stage.replaceCategories(source.id, kind, [
        for (final c in parsed)
          CategoriesCompanion.insert(
            sourceId: source.id,
            kind: kind,
            categoryId: c.id,
            name: c.name,
          ),
      ]);
    }

    onStage?.call('Loading live channels…');
    if (await body(CatalogFeed.channels, 'get_live_streams')
        case final liveBody?) {
      final liveStreams = await compute(parseLiveStreams, liveBody);
      await stage.replaceLiveChannels(source.id, [
        for (final s in liveStreams)
          LiveChannelsCompanion.insert(
            sourceId: source.id,
            streamId: s.streamId,
            name: s.name,
            icon: Value(s.icon),
            categoryId: Value(s.categoryId),
            epgChannelId: Value(s.epgChannelId),
            channelNumber: Value(s.number),
          ),
      ]);
    }

    onStage?.call('Loading movies…');
    if (await body(CatalogFeed.movies, 'get_vod_streams') case final vodBody?) {
      final vodStreams = await compute(parseVodStreams, vodBody);
      await stage.replaceMovies(source.id, [
        for (final s in vodStreams)
          MoviesCompanion.insert(
            sourceId: source.id,
            streamId: s.streamId,
            name: s.name,
            icon: Value(s.icon),
            categoryId: Value(s.categoryId),
            containerExtension: Value(s.containerExtension),
            rating: Value(s.rating),
            ratingScale: Value(s.ratingScale),
            releaseYear: Value(s.releaseYear),
            externalId: Value(s.externalId),
            addedAt: Value(s.addedAt),
          ),
      ]);
    }

    onStage?.call('Loading series…');
    if (await body(CatalogFeed.series, 'get_series') case final seriesBody?) {
      final seriesList = await compute(parseSeriesList, seriesBody);
      await stage.replaceSeries(source.id, [
        for (final s in seriesList)
          SeriesItemsCompanion.insert(
            sourceId: source.id,
            seriesId: s.seriesId,
            name: s.name,
            cover: Value(s.cover),
            categoryId: Value(s.categoryId),
            plot: Value(s.plot),
            rating: Value(s.rating),
            ratingScale: Value(s.ratingScale),
            releaseYear: Value(s.releaseYear),
            externalId: Value(s.externalId),
            lastModifiedAt: Value(s.lastModifiedAt),
          ),
      ]);
    }
  }

  // --- M3U ---

  Future<String?> _syncM3u(
    AppDatabase stage,
    Source source,
    _FeedCache cache,
    String? previousGuide,
    void Function(String stage)? onStage,
  ) async {
    onStage?.call('Downloading playlist…');
    final (file, response) = await _download(
      source.serverUrl,
      'playlist.m3u',
      validators: cache.headers(CatalogFeed.playlist),
    );
    try {
      if (!cache.changed(CatalogFeed.playlist, response)) return previousGuide;
      onStage?.call('Importing channels…');
      final path = file.path;
      final result = await Isolate.run(
        () => parseM3uLines(
          File(path)
              .openRead()
              .transform(const Utf8Decoder(allowMalformed: true))
              .transform(const LineSplitter()),
        ),
      );
      if (result.entries.isEmpty) {
        throw Exception('Playlist contained no channels — check the URL.');
      }

      final live = <int, M3uEntry>{};
      final vod = <int, M3uEntry>{};
      for (final e in result.entries) {
        (e.isVod ? vod : live).putIfAbsent(e.streamId, () => e);
      }

      for (final (kind, entries) in [
        (CatalogKind.live, live.values),
        (CatalogKind.vod, vod.values),
      ]) {
        final groups = entries.map((e) => e.group).nonNulls.toSet().toList()
          ..sort();
        await stage.replaceCategories(source.id, kind, [
          for (final g in groups)
            CategoriesCompanion.insert(
              sourceId: source.id,
              kind: kind,
              categoryId: g,
              name: g,
            ),
        ]);
      }

      await stage.replaceLiveChannels(source.id, [
        for (final e in live.values)
          LiveChannelsCompanion.insert(
            sourceId: source.id,
            streamId: e.streamId,
            name: e.name,
            icon: Value(e.logo),
            categoryId: Value(e.group),
            epgChannelId: Value(e.tvgId?.toLowerCase()),
            channelNumber: Value(e.channelNumber),
            streamUrl: Value(e.url),
          ),
      ]);

      await stage.replaceMovies(source.id, [
        for (final e in vod.values)
          MoviesCompanion.insert(
            sourceId: source.id,
            streamId: e.streamId,
            name: e.name,
            icon: Value(e.logo),
            categoryId: Value(e.group),
            containerExtension: Value(e.containerExtension),
            streamUrl: Value(e.url),
          ),
      ]);

      return result.epgUrl;
    } finally {
      await _deleteQuietly(file);
    }
  }

  // --- EPG (XMLTV, both source types) ---

  Future<void> _syncEpg(
    AppDatabase stage,
    File stagedFile,
    Source source,
    String? discoveredGuide,
    void Function(String stage)? onStage,
  ) async {
    final url = switch (source.sourceType) {
      SourceType.m3u => source.epgUrl ?? discoveredGuide,
      SourceType.xtream =>
        source.epgUrl ??
            '${source.serverUrl}/xmltv.php?username=${Uri.encodeQueryComponent(source.username)}&password=${Uri.encodeQueryComponent(source.password)}',
    };
    if (url == null || url.isEmpty) return;

    final channelIds = await _db.epgChannelIds(source.id);
    final rows = await _db.watchLiveChannels(source.id, limit: null).first;
    if (rows.isEmpty) return;
    final directory = await _groupForGuide(rows);
    final manual = await _db.liveGuideLinksFor(source.id);
    channelIds.addAll(
      manual.where((link) => link.manual).map((link) => link.guideId),
    );
    if (channelIds.isEmpty &&
        source.epgUrl == null &&
        discoveredGuide == null &&
        directory.stations.every((station) => station.regional == null)) {
      return;
    }

    onStage?.call('Loading TV guide…');
    final (file, _) = await _download(url, 'epg.xml');
    try {
      final names = await readXmltvChannelNames(file.path);
      final links = matchLiveGuide(directory, names);
      channelIds.addAll(links.values);
      final now = DateTime.now().toUtc();
      final batches = parseXmltvFileInIsolate(
        file.path,
        wantedChannels: channelIds,
        minEnd: now.subtract(epgLookback),
        maxStart: now.add(epgHorizon),
      );
      await for (final batch in batches) {
        await stage.insertEpgBatch([
          for (final p in batch)
            EpgProgrammesCompanion.insert(
              sourceId: source.id,
              channelId: p.channelId,
              startAt: p.start,
              endAt: p.end,
              title: p.title,
              description: Value(p.description),
            ),
        ]);
      }
      await _db.publishImport(
        stagedFile,
        source,
        automaticGuideLinks: links,
        guideNames: names,
      );
    } finally {
      await _deleteQuietly(file);
    }
  }

  Future<(File, Response<Object?>)> _download(
    String url,
    String suffix, {
    Map<String, String> validators = const {},
  }) async {
    final dir = await Directory.systemTemp.createTemp('zauxoflix_sync');
    final file = File('${dir.path}/$suffix');
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
    try {
      final response = await dio.download(
        url,
        file.path,
        options: Options(
          headers: validators,
          validateStatus: (s) =>
              s != null &&
              (s >= 200 && s < 300 || s == 304 && validators.isNotEmpty),
        ),
      );
      return (file, response);
    } on DioException catch (e) {
      await _deleteQuietly(file);
      throw Exception(switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
          'Download timed out — check the URL.',
        DioExceptionType.badResponse =>
          'Server rejected the request (HTTP ${e.response?.statusCode}).',
        _ => 'Could not download: ${e.message}',
      });
    } finally {
      dio.close();
    }
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      await file.parent.delete(recursive: true);
    } catch (_) {}
  }
}

/// User-presentable sync error. A raw [DioException].toString() embeds the
/// request URL — which for Xtream carries the account's username/password in
/// query parameters — so it must never reach the UI or logs.
String syncErrorMessage(Object e) {
  if (e is DioException) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'Connection timed out — check the server URL.',
      DioExceptionType.badResponse =>
        'Server rejected the request (HTTP ${e.response?.statusCode}).',
      _ => 'Network error — check the server URL and connection.',
    };
  }
  // A JSON parse failure embeds the raw (unparseable) server body in its
  // toString() — which can leak the URL/credentials or a provider error page.
  // Keep it generic instead.
  if (e is FormatException) {
    return 'The server returned an unexpected response. '
        'Check the server URL and credentials.';
  }
  if (e is XtreamApiException) return e.message;
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring('Exception: '.length) : s;
}
