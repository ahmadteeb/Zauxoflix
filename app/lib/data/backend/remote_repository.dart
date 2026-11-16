import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_identity.dart';

import 'remote_models.dart';

/// A backend rejection from the remote-control routes.
class RemoteException implements Exception {
  const RemoteException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'RemoteException($code)';
}

/// Sends short-lived commands through Supabase Realtime to account devices.
class RemoteRepository {
  RemoteRepository(this._client, this._device);

  final SupabaseClient _client;
  final DeviceIdentity _device;

  Future<List<RemoteDevice>> devices() async {
    final rows = await _client.rpc<List<dynamic>>('read_devices');
    return [
      for (final row in rows.cast<Map<String, dynamic>>())
        if (row['deviceId'] != _device.deviceId)
          RemoteDevice.fromJson({
            ...row,
            'online': DateTime.parse(
              row['lastSeenAt'] as String,
            ).isAfter(DateTime.now().subtract(const Duration(seconds: 75))),
          }),
    ];
  }

  Future<void> play({
    required String targetDeviceId,
    required PlaybackIdentity identity,
    int positionSec = 0,
  }) => _command({
    'action': 'play',
    'targetDeviceId': targetDeviceId,
    ...identity.toJson(),
    'positionSec': positionSec,
  });

  Future<void> seek(String targetDeviceId, int positionSec) => _command({
    'action': 'seek',
    'targetDeviceId': targetDeviceId,
    'positionSec': positionSec,
  });

  /// pause | resume | next | prev | stop.
  Future<void> transport(String targetDeviceId, String action) =>
      _command({'action': action, 'targetDeviceId': targetDeviceId});

  Future<void> _command(Map<String, dynamic> body) async {
    try {
      await _client.rpc<void>(
        'send_remote_event',
        params: {
          'sender_device': _device.deviceId,
          'target_device': body['targetDeviceId'],
          'event_kind': 'remote',
          'event_payload': body,
        },
      );
    } catch (_) {
      throw const RemoteException(
        'device_offline',
        'Could not reach that device. Please try again.',
      );
    }
  }

  Future<void> reportStatus(RemoteStatus status) async {
    try {
      await _client.rpc<void>(
        'send_remote_event',
        params: {
          'sender_device': _device.deviceId,
          'target_device': null,
          'event_kind': 'remote-status',
          'event_payload': status.toJson(),
        },
      );
    } catch (_) {}
  }
}
