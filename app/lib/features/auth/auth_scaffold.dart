import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Netflix-style backdrop shared by the pre-auth screens: the poster-wall
/// artwork under a dark scrim, with a translucent card that carries the
/// wordmark above the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.child, this.maxWidth = 440});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // Keeps the form legible over the artwork's bright patches.
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.55),
                Colors.black.withValues(alpha: 0.72),
                AppColors.background.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Container(
                    padding: EdgeInsets.all(
                      MediaQuery.sizeOf(context).width < 600 ? 20 : 32,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Zauxoflix',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A red-tinted banner for form-level errors, matching Netflix's inline style.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }
}
