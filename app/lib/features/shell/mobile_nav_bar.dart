import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'destinations.dart';
import 'navigation_glass.dart';

class MobileNavBar extends StatelessWidget {
  const MobileNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    this.glass = false,
  });

  static final _branchIndices = [
    for (final (index, destination) in appDestinations.indexed)
      if (destination.inMobileDock) index,
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final slot = _branchIndices.indexOf(selectedIndex);
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 210);
    final largeLabels = MediaQuery.textScalerOf(context).scale(12) > 16;

    final tabs = Padding(
      padding: const EdgeInsets.all(4),
      child: SizedBox(
        height: largeLabels ? 72 : 57,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedAlign(
              alignment: AlignmentDirectional(
                slot < 0 ? -1 : 2 * slot / (_branchIndices.length - 1) - 1,
                0,
              ),
              duration: motion,
              curve: Curves.easeOutCubic,
              child: FractionallySizedBox(
                widthFactor: 1 / _branchIndices.length,
                heightFactor: 1,
                child: AnimatedOpacity(
                  opacity: slot < 0 ? 0 : 1,
                  duration: motion,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppColors.selectionGradient,
                      borderRadius: BorderRadius.circular(18),
                      border: glass
                          ? Border.all(
                              color: AppColors.selectionAccent.withValues(
                                alpha: .35,
                              ),
                            )
                          : null,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 16,
                        height: 2,
                        decoration: BoxDecoration(
                          color: AppColors.selectionAccent,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            FocusTraversalGroup(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final index in _branchIndices)
                    Expanded(
                      child: _MobileDestination(
                        destination: appDestinations[index],
                        selected: selectedIndex == index,
                        onPressed: () => onSelect(index),
                        motion: motion,
                        inactiveColor: glass
                            ? NavigationGlass.foreground
                            : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return DecoratedBox(
      decoration: glass
          ? const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [.22, 1],
                colors: [Colors.transparent, Color(0x790B0B0F)],
              ),
            )
          : const BoxDecoration(color: AppColors.background),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: glass ? 10 : 6),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, glass ? 8 : 5, 12, 0),
          child: Align(
            alignment: Alignment.center,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: NavigationGlass(
                radius: 22,
                enabled: glass,
                blur: true,
                child: tabs,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileDestination extends StatelessWidget {
  const _MobileDestination({
    required this.destination,
    required this.selected,
    required this.onPressed,
    required this.motion,
    required this.inactiveColor,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onPressed;
  final Duration motion;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
          foregroundColor: selected ? AppColors.textPrimary : inactiveColor,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          animationDuration: motion,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected
                  ? destination.icon
                  : destination.outlineIcon ?? destination.icon,
              color: selected ? AppColors.selectionAccent : null,
              size: 22,
            ),
            const SizedBox(height: 3),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  destination.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
