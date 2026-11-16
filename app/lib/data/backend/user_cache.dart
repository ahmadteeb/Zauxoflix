import 'dart:convert';

import 'auth_models.dart';
import 'key_value_store.dart';

/// Persists the signed-in user's profile so an offline cold start can restore
/// the session, and so a login by a *different* account can be detected (and
/// the previous account's local data purged).
class UserCache {
  UserCache(this._store);

  final KeyValueStore _store;

  static const _kUser = 'auth.user';

  Future<BackendUser?> read() async {
    final raw = await _store.read(_kUser);
    if (raw == null) return null;
    try {
      return BackendUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  Future<void> save(BackendUser user) =>
      _store.write(_kUser, jsonEncode(user.toJson()));

  Future<void> clear() => _store.delete(_kUser);
}
