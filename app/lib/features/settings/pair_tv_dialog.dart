import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/dpad_text_field.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/pairing_repository.dart';
import 'pair_tv_scanner.dart';

/// Claims the code shown on a TV's sign-in screen, binding that device to this
/// account. Resolves with the TV's label (or '' when it sent none) on success.
Future<String?> showPairTvDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _PairTvDialog(),
  );
}

class _PairTvDialog extends ConsumerStatefulWidget {
  const _PairTvDialog();

  @override
  ConsumerState<_PairTvDialog> createState() => _PairTvDialogState();
}

class _PairTvDialogState extends ConsumerState<_PairTvDialog> {
  final _code = TextEditingController();
  bool _busy = false;
  bool _scanning = false;
  bool _scanned = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    FocusScope.of(context).unfocus();
    setState(() => _scanning = true);
    try {
      final code = await ref.read(pairingScannerProvider)(
        context,
        ref.read(pairingProjectProvider),
      );
      if (!mounted || code == null) return;
      setState(() {
        _code.text = code;
        _scanned = true;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Could not open the camera. Enter the TV code manually.',
        );
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  Future<void> _submit() async {
    final code = _code.text.trim();
    if (_busy || _scanning) return;
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code shown on the TV.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final label = await ref.read(pairingRepositoryProvider).claim(code);
      if (mounted) Navigator.pop(context, label ?? '');
    } on PairingException catch (error) {
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
      title: const Text('Pair a TV'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'On the TV, choose "Pair a TV with a code". Scan its QR code '
              'or enter the displayed code, then choose Pair.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            if (ref.watch(pairingCameraSupportedProvider)) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _busy || _scanning ? null : _scan,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Scan QR code'),
              ),
            ],
            const SizedBox(height: 16),
            DpadTextField(
              autofocus: !ref.watch(pairingCameraSupportedProvider),
              builder: (context, fieldNode) => TextField(
                controller: _code,
                focusNode: fieldNode,
                enabled: !_busy && !_scanning,
                textCapitalization: TextCapitalization.characters,
                onChanged: (_) {
                  if (_scanned) setState(() => _scanned = false);
                },
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: 'TV code',
                  hintText: 'e.g. K7QM4T9A',
                ),
              ),
            ),
            if (_scanned) ...[
              const SizedBox(height: 12),
              const Text(
                'Check that this code matches your TV, then choose Pair to sign it in.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
          onPressed: _busy || _scanning ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pair'),
        ),
      ],
    );
  }
}
