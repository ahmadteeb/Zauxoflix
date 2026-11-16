import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/backend/pairing_qr.dart';

import '../../core/theme/app_theme.dart';
import '../../data/backend/backend_providers.dart';
import '../../data/backend/pairing_models.dart';
import '../../data/backend/pairing_repository.dart';
import 'auth_scaffold.dart';

/// TV / set-top pairing: the device shows a short code, the user enters it on a
/// phone or the web where they're already signed in, and this screen polls until
/// the backend hands back a session. Typing an email + password with a remote is
/// painful, so this is the preferred sign-in path on the ten-foot UI.
class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen> {
  PairingStart? _pairing;
  String? _error; // fatal: couldn't obtain a code at all
  bool _expired = false;
  bool _loading = true;
  Duration _remaining = Duration.zero;

  // Bumped on restart / claim / dispose so any in-flight poll loop or ticker
  // bound to an older generation exits without touching current state.
  int _generation = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    _generation++;
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _begin() async {
    final gen = ++_generation;
    _ticker?.cancel();
    setState(() {
      _loading = true;
      _error = null;
      _expired = false;
      _pairing = null;
    });
    try {
      final pairing = await ref.read(pairingRepositoryProvider).start();
      if (!mounted || gen != _generation) return;
      setState(() {
        _pairing = pairing;
        _loading = false;
      });
      _startTicker(gen, pairing.expiresAt);
      unawaited(_pollLoop(gen, pairing));
    } on PairingException catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = 'Could not reach the server. Check your connection.';
        _loading = false;
      });
    }
  }

  void _startTicker(int gen, DateTime expiresAt) {
    _ticker?.cancel();
    void tick() {
      if (!mounted || gen != _generation) return;
      final left = expiresAt.difference(DateTime.now());
      if (left <= Duration.zero) {
        _markExpired(gen);
        return;
      }
      setState(() => _remaining = left);
    }

    tick();
    if (!_expired) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    }
  }

  Future<void> _pollLoop(int gen, PairingStart pairing) async {
    while (mounted && gen == _generation) {
      await Future<void>.delayed(pairing.pollInterval);
      if (!mounted || gen != _generation) return;
      if (!pairing.expiresAt.isAfter(DateTime.now())) {
        _markExpired(gen);
        return;
      }
      try {
        final result = await ref
            .read(pairingRepositoryProvider)
            .poll(pairing.deviceSecret);
        if (!mounted || gen != _generation) return;
        if (result is PairingClaimed) {
          _ticker?.cancel();
          _generation++; // stop this loop before we hand off to the router
          await ref
              .read(authControllerProvider.notifier)
              .completePairing(result.session);
          return; // the auth gate redirects away from /pair
        }
      } on PairingException catch (e) {
        if (!mounted || gen != _generation) return;
        if (e.needsRestart) {
          _markExpired(gen);
          return;
        }
        // Transient (network blip, account check) — keep polling silently.
      } catch (_) {
        // Transient failure; keep polling until the code actually expires.
      }
    }
  }

  void _markExpired(int gen) {
    if (!mounted || gen != _generation) return;
    _ticker?.cancel();
    setState(() => _expired = true);
  }

  String _countdown(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(maxWidth: 880, child: _buildBody(context));
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Requesting a pairing code…',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    if (_error != null) {
      return _MessageState(
        icon: Icons.wifi_off_rounded,
        title: 'Couldn\'t start pairing',
        message: _error!,
        primaryLabel: 'Try again',
        onPrimary: _begin,
        onBackToSignIn: () => context.go('/login'),
      );
    }

    if (_expired) {
      return _MessageState(
        icon: Icons.timer_off_rounded,
        title: 'Code expired',
        message: 'That pairing code timed out before it was entered.',
        primaryLabel: 'Get a new code',
        onPrimary: _begin,
        onBackToSignIn: () => context.go('/login'),
      );
    }

    final pairing = _pairing!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Connect your TV',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        const Text(
          'On your signed-in device, open Settings → Pair a TV.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final qrSize = (constraints.maxWidth * .44).clamp(112.0, 224.0);
              return Row(
                key: const ValueKey('pairing-credentials'),
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: QrImageView(
                      data: PairingQr.encode(
                        pairing.code,
                        ref.watch(pairingProjectProvider),
                      ),
                      size: qrSize,
                      padding: const EdgeInsets.all(12),
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                      semanticsLabel: 'Scan in Zauxoflix to pair this TV.',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'TV code',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Semantics(
                          label: 'TV code: ${pairing.code.split('').join(' ')}',
                          excludeSemantics: true,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              pairing.code,
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Scan the QR in Zauxoflix or enter the TV code, then choose Pair.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            Text(
              'Waiting… expires in ${_countdown(_remaining)}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.go('/login'),
          child: const Text('Sign in with email instead'),
        ),
      ],
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBackToSignIn,
  });

  final IconData icon;
  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onBackToSignIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(icon, size: 52, color: AppColors.primary),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 28),
        FilledButton(
          onPressed: onPrimary,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(primaryLabel),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onBackToSignIn,
          child: const Text('Sign in with email instead'),
        ),
      ],
    );
  }
}
