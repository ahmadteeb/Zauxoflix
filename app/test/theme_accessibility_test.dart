import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';

double contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return (first > second ? first + .05 : second + .05) /
      (first > second ? second + .05 : first + .05);
}

void main() {
  test(
    'dark theme body, secondary, error and action text meet contrast targets',
    () {
      for (final surface in [
        AppColors.background,
        AppColors.surface,
        AppColors.surfaceLight,
      ]) {
        expect(
          contrast(AppColors.textPrimary, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(AppColors.textSecondary, surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(contrast(AppColors.error, surface), greaterThanOrEqualTo(4.5));
      }
      expect(
        contrast(Colors.white, AppColors.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        contrast(AppColors.focusRing, AppColors.surface),
        greaterThanOrEqualTo(3),
      );
    },
  );
}
