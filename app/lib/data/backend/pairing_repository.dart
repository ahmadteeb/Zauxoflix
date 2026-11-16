import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_models.dart';
import 'auth_repository.dart' show userProfile;
import 'pairing_models.dart';

class PairingException implements Exception {
  const PairingException(this.code, this.message);
  final String code;
  final String message;
  bool get needsRestart =>
      code == 'pairing_expired' || code == 'pairing_not_found';
}

class PairingRepository {
  PairingRepository(this._client);
  final SupabaseClient _client;

  Future<Map<String, dynamic>> _invoke(Map<String, dynamic> body) async {
    try {
      final response = await _client.functions.invoke('tv-pairing', body: body);
      return Map<String, dynamic>.from(response.data as Map);
    } on FunctionException catch (e) {
      final details = e.details;
      final code = details is Map ? details['error'] as String? : null;
      throw PairingException(code ?? 'pairing_unavailable', switch (code) {
        'rate_limited' => 'Too many attempts. Please wait a minute.',
        'pairing_expired' ||
        'pairing_not_found' => 'This code expired. Get a new one.',
        'invalid_pairing_code' => 'Check the code on your TV and try again.',
        _ => 'Could not pair this TV. Please try again.',
      });
    } catch (_) {
      throw const PairingException(
        'network_error',
        'Could not connect. Please try again.',
      );
    }
  }

  Future<PairingStart> start({String? deviceLabel}) async =>
      PairingStart.fromJson(
        await _invoke({'action': 'start', 'deviceLabel': deviceLabel}),
      );
  Future<PairingPollResult> poll(String deviceSecret) async {
    final data = await _invoke({
      'action': 'poll',
      'deviceSecret': deviceSecret,
    });
    if (data['status'] != 'claimed') return const PairingPending();
    try {
      final result = await _client.auth.verifyOTP(
        tokenHash: data['tokenHash'] as String,
        type: OtpType.magiclink,
      );
      return PairingClaimed(LoginResult(user: userProfile(result.user!)));
    } catch (_) {
      throw const PairingException(
        'pairing_expired',
        'Could not sign in. Get a new code.',
      );
    }
  }

  Future<String?> claim(String code) async =>
      (await _invoke({'action': 'claim', 'code': code}))['deviceLabel']
          as String?;
}
