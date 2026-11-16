import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/backend/auth_repository.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/providers.dart';
import 'auth_scaffold.dart';
import 'forgot_password_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(_email.text.trim(), _password.text);
      // The router's auth gate navigates away once state is Authenticated.
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = await showForgotPasswordDialog(
      context,
      initialEmail: _email.text.trim(),
    );
    if (email == null || !mounted) return;
    _email.text = email;
    _password.clear();
    setState(() => _error = null);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Password reset'),
        content: const Text('Sign in with your new password.'),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // While the stored session is being restored the router keeps the app on
    // the splash screen, so this can always render the form.
    // Sign-in waits for the catalog sync; surface its stage under the spinner.
    final syncStage = switch (ref.watch(syncControllerProvider)) {
      SyncRunning(:final stage) => stage,
      _ => null,
    };

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sign In',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              AuthErrorBanner(_error!),
              const SizedBox(height: 16),
            ],
            DpadTextField(
              builder: (context, fieldNode) => TextFormField(
                controller: _email,
                focusNode: fieldNode,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? 'Enter your email' : null,
              ),
            ),
            const SizedBox(height: 16),
            DpadTextField(
              builder: (context, fieldNode) => TextFormField(
                controller: _password,
                focusNode: fieldNode,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _submitting ? null : _forgotPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
            if (_submitting) ...[
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  syncStage ?? 'Signing in…',
                  key: ValueKey(syncStage),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _submitting ? null : () => context.go('/pair'),
              icon: const Icon(Icons.tv_rounded, size: 18),
              label: const Text('Pair a TV with a code'),
            ),
            ...[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'New to Zauxoflix?',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => context.go('/register'),
                    child: const Text(
                      'Sign up now',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
