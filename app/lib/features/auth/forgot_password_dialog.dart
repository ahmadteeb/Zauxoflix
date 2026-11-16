import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/backend/auth_repository.dart';
import '../../data/backend/backend_providers.dart';

/// Two-step reset: submit your email to receive a code, then redeem the code
/// with a new password. Resolves with the email whose password was reset, so
/// the login form can prefill it.
Future<String?> showForgotPasswordDialog(
  BuildContext context, {
  String? initialEmail,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _ForgotPasswordDialog(initialEmail: initialEmail),
  );
}

class _ForgotPasswordDialog extends ConsumerStatefulWidget {
  const _ForgotPasswordDialog({this.initialEmail});

  final String? initialEmail;

  @override
  ConsumerState<_ForgotPasswordDialog> createState() =>
      _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<_ForgotPasswordDialog> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _codeStep = false;
  bool _busy = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Step 1 submit: email the code, then advance to the code step.
  Future<void> _sendCode() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Enter your email.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _busy = false;
          _codeStep = true;
          _notice =
              'If that email has an account, a code is on its way. '
              'Enter the code from that email below.';
        });
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = error.message;
        });
      }
    }
  }

  /// Step 2 submit: redeem the code with the new password.
  Future<void> _reset() async {
    final email = _email.text.trim();
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Enter the reset code.');
      return;
    }
    if (_password.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            email: email,
            code: _code.text.trim(),
            newPassword: _password.text,
          );
      if (mounted) Navigator.pop(context, email);
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Reset password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_codeStep) ...[
              const Text(
                'Enter your email and we\'ll send you a reset code.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              DpadTextField(
                autofocus: true,
                builder: (context, fieldNode) => TextField(
                  controller: _email,
                  focusNode: fieldNode,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  onSubmitted: (_) => _sendCode(),
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
            ] else ...[
              Text(
                _notice ??
                    'Enter the reset code from your email, then '
                        'choose a new password.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              DpadTextField(
                builder: (context, fieldNode) => TextField(
                  controller: _email,
                  focusNode: fieldNode,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
              ),
              const SizedBox(height: 12),
              DpadTextField(
                autofocus: true,
                builder: (context, fieldNode) => TextField(
                  controller: _code,
                  focusNode: fieldNode,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Reset code',
                    hintText: 'Email verification code',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DpadTextField(
                builder: (context, fieldNode) => TextField(
                  controller: _password,
                  focusNode: fieldNode,
                  enabled: !_busy,
                  obscureText: true,
                  onSubmitted: (_) => _reset(),
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    helperText: 'At least 8 characters',
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: _busy ? null : (_codeStep ? _reset : _sendCode),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_codeStep ? 'Reset password' : 'Send code'),
        ),
      ],
    );
  }
}
