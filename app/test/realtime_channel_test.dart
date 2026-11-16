import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:zauxoflix/data/backend/device_identity.dart';
import 'package:zauxoflix/data/backend/realtime_channel.dart';

typedef Binding = ({
  sb.PostgresChangeEvent event,
  String? table,
  sb.PostgresChangeFilter? filter,
  void Function(sb.PostgresChangePayload) callback,
});

class RecordingChannel implements sb.RealtimeChannel {
  final bindings = <Binding>[];
  void Function(sb.RealtimeSubscribeStatus, Object?)? status;
  @override
  sb.RealtimeChannel onPostgresChanges({
    required sb.PostgresChangeEvent event,
    String? schema,
    String? table,
    sb.PostgresChangeFilter? filter,
    List<sb.PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(sb.PostgresChangePayload) callback,
  }) {
    expect(schema, 'app_data');
    bindings.add((
      event: event,
      table: table,
      filter: filter,
      callback: callback,
    ));
    return this;
  }

  @override
  sb.RealtimeChannel subscribe([
    void Function(sb.RealtimeSubscribeStatus, Object?)? callback,
    Duration? timeout,
  ]) {
    status = callback;
    return this;
  }

  void emit(String table, Map<String, dynamic> row) {
    bindings
        .firstWhere((binding) => binding.table == table)
        .callback(
          sb.PostgresChangePayload(
            schema: 'app_data',
            table: table,
            commitTimestamp: DateTime.now(),
            eventType: sb.PostgresChangeEvent.insert,
            newRecord: row,
            oldRecord: const {},
            errors: null,
          ),
        );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class RecordingClient extends sb.SupabaseClient {
  RecordingClient()
    : super(
        'https://test.supabase.co',
        'key',
        httpClient: MockClient(
          (request) async => http.Response('', 204, request: request),
        ),
      );
  final channels = <RecordingChannel>[];
  final removed = <sb.RealtimeChannel>[];
  @override
  sb.RealtimeChannel channel(
    String name, {
    sb.RealtimeChannelConfig opts = const sb.RealtimeChannelConfig(),
  }) {
    final channel = RecordingChannel();
    channels.add(channel);
    return channel;
  }

  @override
  Future<String> removeChannel(sb.RealtimeChannel channel) async {
    removed.add(channel);
    return 'ok';
  }
}

void main() {
  late RecordingClient client;
  late RealtimeChannel feed;
  final received = <String>[];
  setUp(() async {
    client = RecordingClient();
    await client.auth.recoverSession(
      jsonEncode({
        'access_token': 'access',
        'refresh_token': 'refresh',
        'expires_in': 3600,
        'token_type': 'bearer',
        'user': {
          'id': 'account',
          'aud': 'authenticated',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    feed = RealtimeChannel(
      client,
      const DeviceIdentity(deviceId: 'this-device', platform: 'linux'),
    );
    received.clear();
    feed.start((type, data) => received.add(type));
  });
  tearDown(() async {
    feed.stop();
    await client.dispose();
  });

  test('subscriptions filter the account and omit cleanup deletes', () {
    final bindings = client.channels.single.bindings;
    expect(bindings, hasLength(7));
    for (final binding in bindings) {
      expect(binding.filter!.column, 'user_id');
      expect(binding.filter!.value, 'account');
      expect(binding.event, isNot(sb.PostgresChangeEvent.all));
      expect(binding.event, isNot(sb.PostgresChangeEvent.delete));
      if (binding.table == 'remote_events') {
        expect(binding.event, sb.PostgresChangeEvent.insert);
      }
    }
  });

  test(
    'remote commands ignore other targets, the sender and expired events',
    () {
      final channel = client.channels.single;
      final event = <String, dynamic>{
        'sender': 'phone',
        'target': 'this-device',
        'kind': 'remote',
        'payload': {'action': 'pause'},
        'expires_at': DateTime.now()
            .add(const Duration(seconds: 30))
            .toIso8601String(),
      };
      channel.emit('remote_events', {...event, 'sender': 'this-device'});
      channel.emit('remote_events', {...event, 'target': 'another-tv'});
      channel.emit('remote_events', {
        ...event,
        'expires_at': DateTime.now()
            .subtract(const Duration(seconds: 1))
            .toIso8601String(),
      });
      expect(received, isEmpty);
      channel.emit('remote_events', event);
      expect(received, ['remote']);
    },
  );

  test(
    'reconnect reconciles while retired channels cannot deliver changes',
    () async {
      final retired = client.channels.single;
      feed.start((type, data) => received.add(type));
      retired.emit('sources', {});
      retired.status!(sb.RealtimeSubscribeStatus.subscribed, null);
      expect(received, isEmpty);
      final active = client.channels.last;
      active.status!(sb.RealtimeSubscribeStatus.subscribed, null);
      expect(received, ['provision']);
      await Future<void>.delayed(Duration.zero);
      feed.stop();
      active.emit('favorites', {});
      expect(received, ['provision']);
      expect(client.removed, containsAll([retired, active]));
    },
  );
}
