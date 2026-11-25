import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

class NavigationGlass extends StatelessWidget {
  const NavigationGlass({
    super.key,
    required this.radius,
    required this.child,
    this.enabled = true,
    this.blur = false,
    this.outlined = true,
  });

  static const foreground = Color(0xFFDEDDE6);
  static final _frost = ImageFilter.blur(sigmaX: 12, sigmaY: 12);

  final double radius;
  final Widget child;
  final bool enabled, blur, outlined;

  @override
  Widget build(BuildContext context) {
    final corners = BorderRadius.circular(radius);
    final highContrast = MediaQuery.highContrastOf(context);
    final translucent = enabled && !highContrast;
    final glass = DecoratedBox(
      decoration: BoxDecoration(
        color: translucent ? null : AppColors.surface,
        gradient: translucent
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xB324242C), Color(0xCD111117)],
              )
            : null,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: outlined || highContrast
              ? Border.all(
                  color: !enabled
                      ? Colors.white10
                      : highContrast
                      ? Colors.white54
                      : const Color(0x4DFFFFFF),
                )
              : null,
          borderRadius: corners,
        ),
        child: child,
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: corners,
        boxShadow: enabled
            ? const [
                BoxShadow(
                  color: Color(0x36000000),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: corners,
        child: BackdropFilter(
          enabled: translucent && blur,
          filter: _frost,
          child: glass,
        ),
      ),
    );
  }
}
