import 'package:drift/drift.dart' show Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import 'provision_models.dart';

class ProvisionRepository {
  ProvisionRepository(this._client, this._db);
  final SupabaseClient _client;
  final AppDatabase _db;
  Future<SourcePayload?> fetch() async {
    final payload = await _client.rpc<Map<String, dynamic>?>('read_source');
    return payload == null ? null : SourcePayload.fromJson(payload);
  }

  /// Upserts the single provisioned source row. Returns true when the local
  /// catalog anchor changed (new or different creds) so the caller can trigger
  /// a re-sync; false when it already matched.
  Future<bool> applyProvisionedSource(SourcePayload payload) =>
      adoptSource(payload).then((result) => result.changed);

  Future<({int id, bool changed})> adoptSource(SourcePayload payload) =>
      _db.transaction(() async {
        final existing = await _db.watchActiveSource().first;
        if (existing != null && payload.matchesPlaylist(existing)) {
          final changed = existing.epgUrl != payload.epgUrl;
          if (changed) {
            await (_db.update(_db.sources)
                  ..where((s) => s.id.equals(existing.id)))
                .write(SourcesCompanion(epgUrl: Value(payload.epgUrl)));
          }
          return (id: existing.id, changed: changed);
        }
        if (existing != null) await _db.deleteSource(existing.id);
        return (
          id: await _db.insertSource(payload.toCompanion()),
          changed: true,
        );
      });

  Future<void> saveXtreamSource({
    required String serverUrl,
    required String username,
    required String password,
  }) => _putSource({
    'type': 'xtream',
    'serverUrl': serverUrl,
    'username': username,
    'password': password,
  });
  Future<void> saveM3uSource({required String m3uUrl, String? epgUrl}) =>
      _putSource({'type': 'm3u', 'm3uUrl': m3uUrl, 'epgUrl': epgUrl});
  Future<void> _putSource(Map<String, dynamic> payload) =>
      _client.rpc<void>('save_source', params: {'source_payload': payload});
  Future<void> deleteRemoteSource() =>
      _client.rpc<void>('save_source', params: {'source_payload': null});
}
