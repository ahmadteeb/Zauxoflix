import 'package:supabase_flutter/supabase_flutter.dart';

import 'key_value_store.dart';

/// Keep Supabase refresh tokens in the platform keychain.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this._store, String projectUrl)
    : _key = 'supabase.${Uri.parse(projectUrl).host}.session';
  final KeyValueStore _store;
  final String _key;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => await _store.read(_key) != null;
  @override
  Future<String?> accessToken() => _store.read(_key);
  @override
  Future<void> removePersistedSession() => _store.delete(_key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_key, persistSessionString);
}
