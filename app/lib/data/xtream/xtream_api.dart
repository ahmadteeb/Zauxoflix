import 'dart:convert';

import 'package:dio/dio.dart';

import 'xtream_models.dart';

class XtreamCredentials {
  XtreamCredentials({
    required String serverUrl,
    required this.username,
    required this.password,
  }) : serverUrl = normalizeServerUrl(serverUrl);

  final String serverUrl;
  final String username;
  final String password;

  /// Users paste anything: bare hosts, trailing slashes, full player_api URLs.
  static String normalizeServerUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    final uri = Uri.parse(url);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }
}

class XtreamApiException implements Exception {
  XtreamApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class XtreamApi {
  XtreamApi(this.credentials, {Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(minutes: 3),
              responseType: ResponseType.plain,
            ),
          );

  final XtreamCredentials credentials;
  final Dio _dio;

  Future<XtreamUserInfo> authenticate() async {
    final body = await raw();
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('not an object');
      }
      return XtreamUserInfo.fromJson(decoded);
    } on FormatException {
      // This portal doesn't speak the Xtream player_api.php protocol — it
      // returned a non-JSON page (often an HTML/404 error). Confirm the login
      // the other way, via the M3U endpoint get.php.
      if (await _playlistLoginOk()) {
        return const XtreamUserInfo(authenticated: true, status: 'Active');
      }
      throw XtreamApiException(
        'Sign-in failed. Check the server address, username and password.',
      );
    }
  }

  /// Verifies credentials against get.php for portals without player_api.php.
  /// A working IPTV account returns a playlist that starts with the #EXTM3U
  /// marker; an error page or empty body means the login was refused.
  Future<bool> _playlistLoginOk() async {
    try {
      final response = await _dio.get<String>(
        '${credentials.serverUrl}/get.php',
        queryParameters: {
          'username': credentials.username,
          'password': credentials.password,
          'type': 'm3u_plus',
          'output': 'ts',
        },
        // Only the first bytes are needed to recognise a valid playlist.
        options: Options(headers: {'Range': 'bytes=0-63'}),
      );
      return (response.data ?? '').trimLeft().startsWith('#EXTM3U');
    } on DioException {
      return false;
    }
  }

  /// Raw JSON body for [action]; large list payloads are parsed off the main
  /// isolate by the caller instead of here.
  Future<String> raw({String? action, Map<String, String>? params}) async {
    final response = await fetch(action: action, params: params);
    return response.data!;
  }

  Future<Response<String>> fetch({
    String? action,
    Map<String, String>? params,
    Map<String, String> validators = const {},
  }) async {
    final query = {
      'username': credentials.username,
      'password': credentials.password,
      'action': ?action,
      ...?params,
    };
    try {
      final response = await _dio.get<String>(
        '${credentials.serverUrl}/player_api.php',
        queryParameters: query,
        options: Options(
          headers: validators,
          validateStatus: (s) =>
              s != null &&
              (s >= 200 && s < 300 || s == 304 && validators.isNotEmpty),
        ),
      );
      final body = response.data;
      if (response.statusCode != 304 && (body == null || body.isEmpty)) {
        throw XtreamApiException('Empty response from server.');
      }
      return response;
    } on DioException catch (e) {
      throw XtreamApiException(switch (e.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
          'Connection timed out — check the server address.',
        DioExceptionType.badResponse =>
          'Server rejected the request (HTTP ${e.response?.statusCode}).',
        _ => 'Could not reach the server: ${e.message}',
      });
    }
  }

  Future<XtreamVodInfo> vodInfo(int streamId) async => parseVodInfo(
    await raw(action: 'get_vod_info', params: {'vod_id': '$streamId'}),
  );

  Future<XtreamSeriesInfo> seriesInfo(int seriesId) async => parseSeriesInfo(
    await raw(action: 'get_series_info', params: {'series_id': '$seriesId'}),
  );

  String liveStreamUrl(int streamId, {String extension = 'ts'}) =>
      '${credentials.serverUrl}/live/${credentials.username}/${credentials.password}/$streamId.$extension';

  String movieUrl(int streamId, String? containerExtension) =>
      '${credentials.serverUrl}/movie/${credentials.username}/${credentials.password}/$streamId.${containerExtension ?? 'mp4'}';

  String seriesEpisodeUrl(int episodeId, String? containerExtension) =>
      '${credentials.serverUrl}/series/${credentials.username}/${credentials.password}/$episodeId.${containerExtension ?? 'mp4'}';
}
