import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/backend/auth_models.dart';
import '../../data/backend/auth_repository.dart';
import '../../data/backend/backend_providers.dart';

/// Resolves true when the profile was saved.
Future<bool?> showEditProfileDialog(BuildContext context, BackendUser user) {
  return showDialog<bool>(
    context: context,
    builder: (context) => _EditProfileDialog(user: user),
  );
}

/// Resolves true when the password was changed.
Future<bool?> showChangePasswordDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => const _ChangePasswordDialog(),
  );
}

class _EditProfileDialog extends ConsumerStatefulWidget {
  const _EditProfileDialog({required this.user});

  final BackendUser user;

  @override
  ConsumerState<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<_EditProfileDialog> {
  late final _firstName = TextEditingController(
    text: widget.user.firstName ?? '',
  );
  late final _lastName = TextEditingController(
    text: widget.user.lastName ?? '',
  );
  late final _phone = TextEditingController(text: widget.user.phone ?? '');
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    String? clean(TextEditingController c) {
      final text = c.text.trim();
      return text.isEmpty ? null : text;
    }

    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            firstName: clean(_firstName),
            lastName: clean(_lastName),
            phone: clean(_phone),
          );
      if (mounted) Navigator.pop(context, true);
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
      title: const Text('Edit profile'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DpadTextField(
              builder: (context, fieldNode) => TextField(
                controller: _firstName,
                focusNode: fieldNode,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
              ),
            ),
            const SizedBox(height: 12),
            DpadTextField(
              builder: (context, fieldNode) => TextField(
                controller: _lastName,
                focusNode: fieldNode,
                enabled: !_busy,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
              ),
            ),
            const SizedBox(height: 12),
            DpadTextField(
              builder: (context, fieldNode) => TextField(
                controller: _phone,
                focusNode: fieldNode,
                enabled: !_busy,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
            ),
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
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_next.text.length < 8) {
      setState(() => _error = 'New password must be at least 8 characters.');
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'Passwords don\'t match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _next.text,
          );
      if (mounted) Navigator.pop(context, true);
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
      title: const Text('Change password'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DpadTextField(
              builder: (context, fieldNode) => TextField(
                controller: _current,
                focusNode: fieldNode,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DpadTextField(
              builder: (context, fieldNode) => TextField(
                controller: _next,
                focusNode: fieldNode,
                enabled: !_busy,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 8 characters',
                ),
              ),
            ),
            const SizedBox(height: 12),
            DpadTextField(
              builder: (context, fieldNode) => TextField(
                controller: _confirm,
                focusNode: fieldNode,
                enabled: !_busy,
                obscureText: true,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your new password the next time you sign in.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
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
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(8),
            backgroundColor: AppColors.primary,
          ),
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Change password'),
        ),
      ],
    );
  }
}
