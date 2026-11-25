import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  IconData? icon,
  Color? surfaceColor,
  required WidgetBuilder body,
}) {
  final reducedMotion = MediaQuery.disableAnimationsOf(context);
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: surfaceColor ?? AppColors.surface,
    barrierColor: const Color(0xA8000000),
    sheetAnimationStyle: reducedMotion ? AnimationStyle.noAnimation : null,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    constraints: const BoxConstraints(maxWidth: 680),
    builder: (sheetContext) {
      final padding = MediaQuery.paddingOf(sheetContext);
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight:
              (MediaQuery.sizeOf(sheetContext).height - padding.top) * .86,
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSheetHeader(title: title, subtitle: subtitle, icon: icon),
              Flexible(
                child: SingleChildScrollView(
                  primary: true,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 2, 16, 12),
                  child: Builder(builder: body),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 12, 10),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: AppColors.error, size: 23),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

/// Shared option row for selectors and sheet actions. Focus and selection
/// have separate treatments so either state stays clear at TV distance.
class AppSheetOption extends StatelessWidget {
  const AppSheetOption({
    super.key,
    required this.title,
    required this.onPressed,
    this.detail,
    this.icon,
    this.trailing,
    this.selected = false,
    this.autofocus = false,
  });

  final String title;
  final VoidCallback onPressed;
  final String? detail;
  final IconData? icon;
  final IconData? trailing;
  final bool selected;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: TextButton(
        autofocus: autofocus,
        onPressed: onPressed,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          ),
          foregroundColor: const WidgetStatePropertyAll(AppColors.textPrimary),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? AppColors.surfaceLight
                : Colors.transparent,
          ),
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.focused)
                  ? AppColors.focusRing
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ).withSelectionGradient(selected),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 21, color: AppColors.textSecondary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (detail != null)
                    Text(
                      detail!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                ],
              ),
            ),
            if (selected || trailing != null) ...[
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_rounded : trailing,
                color: selected
                    ? AppColors.selectionAccent
                    : AppColors.textSecondary,
                size: 22,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class AppSheetSectionLabel extends StatelessWidget {
  const AppSheetSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 12, 5),
    child: Semantics(
      header: true,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
