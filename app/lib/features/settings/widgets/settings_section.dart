import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.label,
    required this.children,
  });
  final String label;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final contrast = MediaQuery.highContrastOf(context);
    final radius = BorderRadius.circular(22);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: contrast ? AppColors.surface : null,
        borderRadius: radius,
        gradient: contrast ? null : AppColors.panelGradient,
      ),
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: contrast
              ? const BorderSide(color: Colors.white54)
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width action with the same focus affordance across input methods.
class SettingsAction extends StatelessWidget {
  const SettingsAction({
    super.key,
    required this.icon,
    required this.title,
    required this.onPressed,
    this.subtitle,
    this.selected = false,
    this.destructive = false,
    this.busy = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onPressed;
  final bool selected, destructive, busy;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? AppColors.error : AppColors.textPrimary;
    return Semantics(
      selected: selected ? true : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: TextButton(
          onPressed: onPressed,
          style: settingsButtonStyle(context, selected: selected).copyWith(
            minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? AppColors.textSecondary
                  : accent,
            ),
          ),
          child: Row(
            children: [
              if (busy)
                const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  icon,
                  size: 22,
                  color: selected ? AppColors.selectionAccent : null,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                selected ? Icons.check_rounded : Icons.chevron_right_rounded,
                size: 19,
                color: selected ? AppColors.selectionAccent : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

ButtonStyle settingsButtonStyle(
  BuildContext context, {
  bool selected = false,
}) =>
    TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.controlSurface,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: MediaQuery.sizeOf(context).width >= 1000 ? 16 : null,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        )
        .copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? const BorderSide(color: AppColors.focusRing, width: 2)
                : BorderSide.none,
          ),
        )
        .withSelectionGradient(selected);

class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
