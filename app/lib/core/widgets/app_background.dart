import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Poster-wall artwork under a heavy scrim, painted once beneath every route.
/// The theme's scaffold color is transparent so pages show it through; screens
/// that need a solid backdrop (the player) set their own color.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        image: DecorationImage(
          image: const AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            AppColors.background.withValues(alpha: 0.88),
            BlendMode.srcOver,
          ),
        ),
      ),
      child: child,
    );
  }
}
