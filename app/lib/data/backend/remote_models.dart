/// Wire models for the play-on-device relay (Supabase Realtime).
library;

/// Server-side identity of a playable item, matching the sync schema:
/// movies/live carry the provider stream id, series carry the series id plus
/// the episode id. Lets another device resolve the same item in its own
/// synced catalog and build its own stream URL.
class PlaybackIdentity {
  const PlaybackIdentity({
    required this.itemType,
    required this.itemId,
    this.episodeId,
  });

  /// 'LIVE' | 'MOVIE' | 'SERIES'.
  final String itemType;
  final String itemId;
  final String? episodeId;

  Map<String, dynamic> toJson() => {
    'itemType': itemType,
    'itemId': itemId,
    if (episodeId != null) 'episodeId': episodeId,
  };

  static PlaybackIdentity? parse(Map<String, dynamic> json) {
    final itemType = json['itemType'];
    final itemId = json['itemId'];
    if (itemType is! String || itemId is! String) return null;
    return PlaybackIdentity(
      itemType: itemType,
      itemId: itemId,
      episodeId: json['episodeId'] as String?,
    );
  }
}

class RemoteDevice {
  const RemoteDevice({
    required this.deviceId,
    required this.online,
    this.platform,
    this.label,
    this.lastSeenAt,
  });

  final String deviceId;
  final bool online;
  final String? platform;
  final String? label;
  final DateTime? lastSeenAt;

  factory RemoteDevice.fromJson(Map<String, dynamic> json) => RemoteDevice(
    deviceId: json['deviceId'] as String,
    online: json['online'] as bool? ?? false,
    platform: json['platform'] as String?,
    label: json['label'] as String?,
    lastSeenAt: DateTime.tryParse(json['lastSeenAt'] as String? ?? ''),
  );

  bool get isTv => switch (platform) {
    'androidtv' || 'webos' || 'tizen' => true,
    _ => false,
  };

  String get displayName {
    final label = this.label?.trim();
    if (label != null && label.isNotEmpty) return label;
    return switch (platform) {
      'androidtv' => 'Android TV',
      'webos' => 'LG webOS TV',
      'tizen' => 'Samsung TV',
      'android' => 'Android phone',
      'ios' => 'iPhone',
      'linux' => 'Linux device',
      'windows' => 'Windows PC',
      'macos' => 'Mac',
      _ => 'Device',
    };
  }
}

/// A playback command received over Realtime from another of the account's devices.
class RemoteCommand {
  const RemoteCommand({
    required this.action,
    this.identity,
    this.positionSec = 0,
  });

  /// play | pause | resume | seek | next | prev | stop.
  final String action;

  /// Set for play.
  final PlaybackIdentity? identity;

  /// Start position for play, target position for seek.
  final int positionSec;

  static RemoteCommand? parse(Map<String, dynamic> json) {
    final action = json['action'];
    if (action is! String) return null;
    final identity = PlaybackIdentity.parse(json);
    if (action == 'play' && identity == null) return null;
    return RemoteCommand(
      action: action,
      identity: identity,
      positionSec: (json['positionSec'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Another device's transport state, received over Realtime (remote-status) or
/// reported by this device's player through the remote event RPC.
class RemoteStatus {
  const RemoteStatus({
    required this.deviceId,
    required this.state,
    this.identity,
    this.title = '',
    this.subtitle = '',
    this.positionSec = 0,
    this.durationSec = 0,
    this.hasPrev = false,
    this.hasNext = false,
    this.receivedAt,
  });

  final String deviceId;

  /// loading | playing | paused | idle.
  final String state;
  final PlaybackIdentity? identity;
  final String title;
  final String subtitle;
  final int positionSec;
  final int durationSec;
  final bool hasPrev;
  final bool hasNext;

  /// When this snapshot arrived — the remote UI extrapolates the position
  /// from it while playing.
  final DateTime? receivedAt;

  bool get live => identity?.itemType == 'LIVE';

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'state': state,
    ...?identity?.toJson(),
    if (title.isNotEmpty) 'title': title,
    if (subtitle.isNotEmpty) 'subtitle': subtitle,
    'positionSec': positionSec,
    'durationSec': durationSec,
    'hasPrev': hasPrev,
    'hasNext': hasNext,
  };

  static RemoteStatus? parse(Map<String, dynamic> json) {
    final deviceId = json['deviceId'];
    final state = json['state'];
    if (deviceId is! String || state is! String) return null;
    return RemoteStatus(
      deviceId: deviceId,
      state: state,
      identity: PlaybackIdentity.parse(json),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      positionSec: (json['positionSec'] as num?)?.toInt() ?? 0,
      durationSec: (json['durationSec'] as num?)?.toInt() ?? 0,
      hasPrev: json['hasPrev'] as bool? ?? false,
      hasNext: json['hasNext'] as bool? ?? false,
      receivedAt: DateTime.now(),
    );
  }
}
