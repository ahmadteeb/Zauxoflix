import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'device_identity.dart';

/// RLS restricts all change feeds to the signed-in account.
class RealtimeChannel {
  RealtimeChannel(this._client, this._device);
  final sb.SupabaseClient _client;
  final DeviceIdentity _device;
  sb.RealtimeChannel? _channel;
  Timer? _heartbeat;

  void start(void Function(String, Map<String, dynamic>) onEvent) {
    stop();
    final user = _client.auth.currentUser;
    if (user == null) return;
    final channel = _client.channel('account:${user.id}:${_device.deviceId}');
    _channel = channel;
    for (final table in [
      'sources',
      'favorites',
      'watch_progress',
      'remote_events',
    ]) {
      // Subscribe only to authorized row states, never unfiltered cleanup deletes.
      final events = table == 'remote_events'
          ? [sb.PostgresChangeEvent.insert]
          : [sb.PostgresChangeEvent.insert, sb.PostgresChangeEvent.update];
      for (final event in events) {
        channel.onPostgresChanges(
          event: event,
          schema: 'app_data',
          table: table,
          filter: sb.PostgresChangeFilter(
            type: sb.PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (!identical(_channel, channel) ||
                _client.auth.currentUser?.id != user.id) {
              return;
            }
            if (payload.eventType == sb.PostgresChangeEvent.delete) return;
            if (table == 'remote_events') {
              final row = payload.newRecord;
              if (row['sender'] == _device.deviceId) return;
              if (row['target'] != null && row['target'] != _device.deviceId) {
                return;
              }
              final expires = DateTime.tryParse(
                row['expires_at'] as String? ?? '',
              );
              if (expires == null || !expires.isAfter(DateTime.now())) return;
              onEvent(
                row['kind'] as String,
                Map<String, dynamic>.from(row['payload'] as Map),
              );
            } else {
              onEvent(table == 'sources' ? 'provision' : 'sync', {});
            }
          },
        );
      }
    }
    channel.subscribe((status, error) {
      if (!identical(_channel, channel)) return;
      if (status == sb.RealtimeSubscribeStatus.subscribed) {
        // Recover changes missed while the socket was disconnected.
        onEvent('provision', {});
        unawaited(_ping());
      }
    });
    _heartbeat = Timer.periodic(
      const Duration(seconds: 25),
      (_) => unawaited(_ping()),
    );
  }

  Future<void> _ping() async {
    try {
      await _client.rpc<void>(
        'device_heartbeat',
        params: {
          'device_id': _device.deviceId,
          'device_platform': _device.platform,
        },
      );
    } catch (_) {}
  }

  void stop() {
    _heartbeat?.cancel();
    _heartbeat = null;
    final channel = _channel;
    _channel = null;
    if (channel != null) unawaited(_client.removeChannel(channel));
  }
}
