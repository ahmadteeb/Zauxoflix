import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../db/app_database.dart';
import '../epg/xmltv_parser.dart';
import '../m3u/m3u_parser.dart';
import '../xtream/xtream_api.dart';
import '../xtream/xtream_models.dart';

/// Full catalog refresh for one source. Payloads are parsed in background
/// isolates (playlists can be 10k+ rows on 1GB-RAM boxes) and batch-replaced
/// in a single transaction per kind. EPG (XMLTV) is downloaded to a temp
/// file and stream-parsed so it never has to fit in memory.
class CatalogSyncService {
  CatalogSyncService(this._db);

  final AppDatabase _db;

  static const epgLookback = Duration(hours: 3);
  static const epgHorizon = Duration(days: 3);

  Future<void> syncAll(
    Source source, {
    void Function(String stage)? onStage,
  }) async {
    switch (source.sourceType) {
      case SourceType.xtream:
        await _syncXtream(source, onStage);
      case SourceType.m3u:
        await _syncM3u(source, onStage);
    }

    try {
      await _syncEpg(source, onStage);
    } catch (e) {
      // A broken EPG feed shouldn't fail the whole sync — the catalog is fine.
      debugPrint(
        'EPG sync failed for source ${source.id}: ${syncErrorMessage(e)}',
      );
    }

    await _db.markSynced(source.id);
  }

  // --- Xtream ---

  Future<void> _syncXtream(
    Source source,
    void Function(String stage)? onStage,
  ) async {
    final api = XtreamApi(
      XtreamCredentials(
        serverUrl: source.serverUrl,
        username: source.username,
        password: source.password,
      ),
    );

    onStage?.call('Loading categories…');
    for (final (kind, action) in [
      (CatalogKind.live, 'get_live_categories'),
      (CatalogKind.vod, 'get_vod_categories'),
      (CatalogKind.series, 'get_series_categories'),
    ]) {
      final body = await api.raw(action: action);
      final parsed = await compute(parseCategories, body);
      await _db.replaceCategories(source.id, kind, [
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
    final liveBody = await api.raw(action: 'get_live_streams');
    final liveStreams = await compute(parseLiveStreams, liveBody);
    await _db.replaceLiveChannels(source.id, [
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

    onStage?.call('Loading movies…');
    final vodBody = await api.raw(action: 'get_vod_streams');
    final vodStreams = await compute(parseVodStreams, vodBody);
    await _db.replaceMovies(source.id, [
      for (final s in vodStreams)
        MoviesCompanion.insert(
          sourceId: source.id,
          streamId: s.streamId,
          name: s.name,
          icon: Value(s.icon),
          categoryId: Value(s.categoryId),
          containerExtension: Value(s.containerExtension),
          rating: Value(s.rating),
          addedAt: Value(s.addedAt),
        ),
    ]);

    onStage?.call('Loading series…');
    final seriesBody = await api.raw(action: 'get_series');
    final seriesList = await compute(parseSeriesList, seriesBody);
    await _db.replaceSeries(source.id, [
      for (final s in seriesList)
        SeriesItemsCompanion.insert(
          sourceId: source.id,
          seriesId: s.seriesId,
          name: s.name,
          cover: Value(s.cover),
          categoryId: Value(s.categoryId),
          plot: Value(s.plot),
          rating: Value(s.rating),
          lastModifiedAt: Value(s.lastModifiedAt),
        ),
    ]);
  }

  // --- M3U ---

  Future<void> _syncM3u(
    Source source,
    void Function(String stage)? onStage,
  ) async {
    onStage?.call('Downloading playlist…');
    final file = await _download(source.serverUrl, 'playlist.m3u');
    try {
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

      // Discovered url-tvg header becomes the EPG feed unless the user set one.
      if (source.epgUrl == null && result.epgUrl != null) {
        await (_db.update(_db.sources)..where((s) => s.id.equals(source.id)))
            .write(SourcesCompanion(epgUrl: Value(result.epgUrl)));
        source = source.copyWith(epgUrl: Value(result.epgUrl));
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
        await _db.replaceCategories(source.id, kind, [
          for (final g in groups)
            CategoriesCompanion.insert(
              sourceId: source.id,
              kind: kind,
              categoryId: g,
              name: g,
            ),
        ]);
      }

      await _db.replaceLiveChannels(source.id, [
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

      await _db.replaceMovies(source.id, [
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

      await _db.replaceSeries(source.id, const []);
    } finally {
      await _deleteQuietly(file);
    }
  }

  // --- EPG (XMLTV, both source types) ---

  Future<void> _syncEpg(
    Source source,
    void Function(String stage)? onStage,
  ) async {
    final url = switch (source.sourceType) {
      SourceType.m3u => source.epgUrl,
      SourceType.xtream =>
        source.epgUrl ??
            '${source.serverUrl}/xmltv.php?username=${Uri.encodeQueryComponent(source.username)}&password=${Uri.encodeQueryComponent(source.password)}',
    };
    if (url == null || url.isEmpty) return;

    final channelIds = await _db.epgChannelIds(source.id);
    if (channelIds.isEmpty) return;

    onStage?.call('Loading TV guide…');
    final file = await _download(url, 'epg.xml');
    try {
      final now = DateTime.now().toUtc();
      await _db.clearEpg(source.id);
      final batches = parseXmltvFileInIsolate(
        file.path,
        wantedChannels: channelIds,
        minEnd: now.subtract(epgLookback),
        maxStart: now.add(epgHorizon),
      );
      await for (final batch in batches) {
        await _db.insertEpgBatch([
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
    } finally {
      await _deleteQuietly(file);
    }
  }

  Future<File> _download(String url, String suffix) async {
    final dir = await Directory.systemTemp.createTemp('zauxoflix_sync');
    final file = File('${dir.path}/$suffix');
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(minutes: 10),
      ),
    );
    try {
      await dio.download(url, file.path);
      return file;
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
