import 'package:flutter/material.dart';

// Primitives define the palette; semantic aliases and component tokens stay below.
abstract final class AppPalette {
  static const black = Color(0xFF0B0B0F);
  static const gray900 = Color(0xFF16161D);
  static const gray800 = Color(0xFF23232C);
  static const gray400 = Color(0xFF9E9EA7);
  static const gray50 = Color(0xFFF5F5F7);
  static const red600 = Color(0xFFE50914);
  static const red300 = Color(0xFFFF929A);
  static const white = Colors.white;
  static const outline = Color(0x33FFFFFF);
}

abstract final class AppColors {
  static const background = AppPalette.black;
  static const surface = AppPalette.gray900;
  static const surfaceLight = AppPalette.gray800;
  static const primary = AppPalette.red600;
  static const textPrimary = AppPalette.gray50;
  static const textSecondary = AppPalette.gray400;
  static const focusRing = AppPalette.white;
  static const outline = AppPalette.outline;
  static const error = AppPalette.red300;

  // Selection colors come from the phone dock. Focus keeps its white ring.
  static const selectionAccent = AppPalette.red300;
  static const selectionSurface = Color(0xFF4E121B);
  static const selectionGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [selectionSurface, Color(0xFF2B151C)],
  );
  static const controlSurface = Color(0x6631313A);
  static const panelGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [Color(0xDC25252E), Color(0xE8121218)],
  );
}

extension SelectionButtonStyle on ButtonStyle {
  ButtonStyle withSelectionGradient(bool selected) {
    if (!selected) return this;
    return copyWith(
      backgroundBuilder: (context, states, child) {
        if (states.contains(WidgetState.disabled)) {
          return child ?? const SizedBox.shrink();
        }
        final outline =
            shape?.resolve(states) ?? const RoundedRectangleBorder();
        return Ink(
          decoration: ShapeDecoration(
            gradient: AppColors.selectionGradient,
            shape: outline.copyWith(side: side?.resolve(states)),
          ),
          child: child,
        );
      },
    );
  }
}

abstract final class AppSpacing {
  static const medium = 16.0;
  static const large = 24.0;
  static const touchTarget = 48.0;
}

abstract final class AppLayout {
  static const controlMinSize = AppSpacing.touchTarget;
  static const cardPadding = AppSpacing.medium;
  static const sectionGap = AppSpacing.large;
  static const cardRadius = 16.0;
  static const settingsMaxWidth = 760.0;
}

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      fontFamily: 'DM Sans',
      fontFamilyFallback: const ['IBM Plex Sans Arabic'],
      useMaterial3: true,
      brightness: Brightness.dark,
      // Transparent so the app-wide AppBackground artwork shows through.
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceLight,
        error: AppColors.error,
        outline: AppColors.outline,
      ),
    );

    // M3's default focus overlay is nearly invisible on dark surfaces, which
    // strands D-pad users. White wash + bright outline marks the focused
    // control on every button type app-wide.
    final focusOverlay = WidgetStateProperty.resolveWith<Color?>(
      (states) => states.contains(WidgetState.focused) ? Colors.white24 : null,
    );
    final focusSide = WidgetStateProperty.resolveWith<BorderSide?>(
      (states) => states.contains(WidgetState.focused)
          ? const BorderSide(color: AppColors.focusRing, width: 2)
          : null,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        floatingLabelStyle: const TextStyle(color: AppColors.textPrimary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Explicit horizontal padding: styleFrom's padding replaces M3's
          // default entirely, so omitting it renders label text edge-to-edge.
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(
            AppLayout.controlMinSize,
            AppLayout.controlMinSize,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ).copyWith(overlayColor: focusOverlay, side: focusSide),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.textSecondary.withValues(alpha: .45)
                : AppColors.textPrimary,
          ),
          overlayColor: focusOverlay,
          side: focusSide,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.textSecondary.withValues(alpha: .45)
                : AppColors.textPrimary,
          ),
          overlayColor: focusOverlay,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? AppColors.textSecondary.withValues(alpha: .45)
                : AppColors.textPrimary,
          ),
          overlayColor: focusOverlay,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) &&
                  !states.contains(WidgetState.disabled)
              ? AppColors.selectionAccent
              : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) &&
                  !states.contains(WidgetState.disabled)
              ? AppColors.selectionSurface
              : null,
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        selectedIconTheme: IconThemeData(color: AppColors.selectionAccent),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(color: AppColors.textPrimary),
        unselectedLabelTextStyle: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
