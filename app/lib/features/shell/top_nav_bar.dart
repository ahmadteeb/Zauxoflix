import 'package:flutter/material.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../remote/cast_button.dart';
import 'destinations.dart';

const double kTopNavHeight = 72;

class TopNavBar extends StatelessWidget {
  const TopNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.itemFocusNodes,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<FocusNode> itemFocusNodes;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          constraints.maxWidth < 980 ||
          MediaQuery.textScalerOf(context).scale(15) > 22;
      return Container(
        height: kTopNavHeight,
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .72, 1],
            colors: [
              AppColors.background,
              AppColors.background.withValues(alpha: .95),
              AppColors.background.withValues(alpha: 0),
            ],
          ),
        ),
        child: FocusTraversalGroup(
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill,
                color: AppColors.primary,
                size: 30,
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                const Text(
                  'ZAUXOFLIX',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 3,
                  ),
                ),
              ],
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < appDestinations.length; i++) ...[
                        _NavItem(
                          label: appDestinations[i].label,
                          icon: appDestinations[i].icon,
                          iconOnly:
                              compact ||
                              i >=
                                  appDestinations.length - iconOnlyDestinations,
                          selected: i == selectedIndex,
                          focusNode: itemFocusNodes[i],
                          onSelect: () => onSelect(i),
                        ),
                        if (i < appDestinations.length - 1)
                          const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
              ),
              if (!kTvBuild) ...[const SizedBox(width: 8), const CastButton()],
            ],
          ),
        ),
      );
    },
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.iconOnly,
    required this.selected,
    required this.onSelect,
    required this.focusNode,
  });
  final String label;
  final IconData icon;
  final bool iconOnly;
  final bool selected;
  final VoidCallback onSelect;
  final FocusNode focusNode;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: TextButton(
        focusNode: focusNode,
        onPressed: onSelect,
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: iconOnly ? 12 : 18),
          ),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? AppColors.focusRing
                : selected
                ? AppColors.surfaceLight
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? AppColors.background
                : selected
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        child: iconOnly
            ? Icon(icon, size: 22, semanticLabel: label)
            : Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
      ),
    ),
  );
}
