import 'package:drift/drift.dart';

import '../db/app_database.dart';

/// The account's private playlist stored in Supabase.
class SourcePayload {
  const SourcePayload({
    required this.type,
    required this.serverUrl,
    required this.username,
    required this.password,
    this.epgUrl,
  });

  final SourceType type;
  final String serverUrl;
  final String username;
  final String password;
  final String? epgUrl;

  factory SourcePayload.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'm3u') {
      final epg = (json['epgUrl'] as String?)?.trim();
      return SourcePayload(
        type: SourceType.m3u,
        serverUrl: (json['m3uUrl'] as String?)?.trim() ?? '',
        username: '',
        password: '',
        epgUrl: (epg == null || epg.isEmpty) ? null : epg,
      );
    }
    return SourcePayload(
      type: SourceType.xtream,
      serverUrl: (json['serverUrl'] as String?)?.trim() ?? '',
      username: (json['username'] as String?) ?? '',
      password: (json['password'] as String?) ?? '',
    );
  }

  /// True when this payload describes the same source already stored locally,
  /// so provisioning can skip a needless catalog re-sync.
  bool matches(Source existing) =>
      existing.sourceType == type &&
      existing.serverUrl == serverUrl &&
      existing.username == username &&
      existing.password == password &&
      existing.epgUrl == epgUrl;

  SourcesCompanion toCompanion() => SourcesCompanion(
    name: Value(Uri.tryParse(serverUrl)?.host ?? 'Source'),
    sourceType: Value(type),
    serverUrl: Value(serverUrl),
    username: Value(username),
    password: Value(password),
    epgUrl: Value(epgUrl),
  );
}
