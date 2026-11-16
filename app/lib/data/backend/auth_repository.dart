import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'auth_models.dart';

class AuthException implements Exception {
  const AuthException(this.code, this.message);
  final String code;
  final String message;
}

BackendUser userProfile(sb.User user) => BackendUser.fromJson({
  ...?user.userMetadata,
  'id': user.id,
  'email': user.email ?? '',
});

class AuthRepository {
  AuthRepository(this.client);
  final sb.SupabaseClient client;

  Future<T> _auth<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on sb.AuthException catch (e) {
      throw AuthException(e.code ?? 'auth_error', e.message);
    } catch (_) {
      throw const AuthException(
        'network_error',
        'Could not connect. Please try again.',
      );
    }
  }

  Future<LoginResult> login(String email, String password) => _auth(() async {
    final result = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return LoginResult(user: userProfile(result.user!));
  });

  Future<LoginResult?> register({
    required String email,
    required String password,
  }) => _auth(() async {
    final result = await client.auth.signUp(email: email, password: password);
    if (result.session == null) return null;
    return LoginResult(user: userProfile(result.user!));
  });

  Future<BackendUser> me() =>
      _auth(() async => userProfile((await client.auth.getUser()).user!));

  Future<BackendUser> updateProfile({
    required String? firstName,
    required String? lastName,
    required String? phone,
  }) => _auth(() async {
    final result = await client.auth.updateUser(
      sb.UserAttributes(
        data: {'firstName': firstName, 'lastName': lastName, 'phone': phone},
      ),
    );
    return userProfile(result.user!);
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _auth(() async {
    await client.auth.signInWithPassword(
      email: client.auth.currentUser!.email!,
      password: currentPassword,
    );
    await client.auth.updateUser(sb.UserAttributes(password: newPassword));
  });

  Future<void> requestPasswordReset(String email) =>
      _auth(() => client.auth.resetPasswordForEmail(email));

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _auth(() async {
    await client.auth.verifyOTP(
      email: email,
      token: code,
      type: sb.OtpType.recovery,
    );
    await client.auth.updateUser(sb.UserAttributes(password: newPassword));
    await client.auth.signOut(scope: sb.SignOutScope.local);
  });

  Future<void> logout() =>
      _auth(() => client.auth.signOut(scope: sb.SignOutScope.local));
}
