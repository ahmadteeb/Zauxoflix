import 'auth_models.dart';

/// Response of the TV pairing start action. The device shows [code] to the user and
/// polls with the private [deviceSecret] until the code is claimed.
class PairingStart {
  const PairingStart({
    required this.code,
    required this.deviceSecret,
    required this.expiresAt,
    required this.pollInterval,
  });

  final String code;
  final String deviceSecret;
  final DateTime expiresAt;
  final Duration pollInterval;

  factory PairingStart.fromJson(Map<String, dynamic> json) => PairingStart(
    code: json['code'] as String,
    deviceSecret: json['deviceSecret'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    pollInterval: Duration(
      seconds: (json['pollIntervalSec'] as num?)?.toInt() ?? 5,
    ),
  );
}

/// Outcome of a single the TV pairing poll action. Still [PairingPending] until the
/// user claims the code from a signed-in device, then [PairingClaimed] carries
/// the freshly issued session (same shape as login).
sealed class PairingPollResult {
  const PairingPollResult();
}

class PairingPending extends PairingPollResult {
  const PairingPending();
}

class PairingClaimed extends PairingPollResult {
  const PairingClaimed(this.session);

  final LoginResult session;
}
