import 'package:flutter/material.dart';

import '../../core/app_platform.dart';
import '../../core/responsive/form_factor.dart';
import '../../core/tv/tv_back_button.dart';
import '../../core/theme/app_theme.dart';
import '../downloads/download_nav_icon.dart';
import '../remote/cast_button.dart';
import 'destinations.dart';
import 'navigation_glass.dart';

const double kTopNavHeight = 64;

class FocusTopBarIntent extends Intent {
  const FocusTopBarIntent();
}

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
      final home = selectedIndex == 0;
      final compact =
          constraints.maxWidth < 860 ||
          MediaQuery.textScalerOf(context).scale(15) > 22;
      final showIcons = compact || constraints.maxWidth >= 1180;
      final showWordmark = !compact && constraints.maxWidth >= 1010;
      final balanceSides =
          constraints.maxWidth >= 1180 &&
          MediaQuery.textScalerOf(context).scale(15) <= 18;
      const sideWidth = 252.0;
      final motion = MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 140);
      final sectionCount = appDestinations.length - iconOnlyDestinations;
      final leading = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kTvBuild && selectedIndex != 0)
            TvBackButton(
              onPressed: () =>
                  Actions.invoke(context, const NavigateBackIntent()),
            )
          else
            const Icon(
              Icons.play_circle_fill,
              color: AppColors.primary,
              size: 30,
            ),
          if (showWordmark) ...[
            const SizedBox(width: 10),
            const Text(
              'ZAUXOFLIX',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: 2.4,
              ),
            ),
          ],
          SizedBox(width: compact ? 6 : 16),
        ],
      );
      final utilities = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!home && !compact)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: SizedBox(
                height: 23,
                width: 1,
                child: ColoredBox(color: Colors.white24),
              ),
            ),
          for (var i = sectionCount; i < appDestinations.length; i++)
            _NavItem(
              destination: appDestinations[i],
              indicator: appDestinations[i].path == '/downloads'
                  ? const DownloadNavIcon()
                  : null,
              showLabel: false,
              showIcon: true,
              inRail: false,
              glass: home,
              motion: motion,
              selected: i == selectedIndex,
              focusNode: itemFocusNodes[i],
              onSelect: () => onSelect(i),
            ),
          if (!kTvBuild) const CastButton(),
        ],
      );
      final trailing = home
          ? NavigationGlass(radius: 17, child: utilities)
          : utilities;

      return Container(
        height: kTopNavHeight,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: home ? const [0, .60, 1] : const [0, .76, 1],
            colors: home
                ? const [
                    Color(0xDE0B0B0F),
                    Color(0xAB0B0B0F),
                    Colors.transparent,
                  ]
                : [
                    AppColors.background,
                    AppColors.background.withValues(alpha: .90),
                    AppColors.background.withValues(alpha: .10),
                  ],
          ),
        ),
        child: FocusTraversalGroup(
          child: Row(
            children: [
              if (balanceSides)
                SizedBox(
                  width: sideWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: leading,
                  ),
                )
              else
                leading,
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: NavigationGlass(
                      radius: 17,
                      enabled: home,
                      // Keep the translucent tint on embedded TVs without a GPU blur.
                      blur: !isWebOsPlatform && !isTizenPlatform,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < sectionCount; i++)
                              _NavItem(
                                destination: appDestinations[i],
                                showLabel: !compact,
                                showIcon: showIcons,
                                inRail: true,
                                glass: home,
                                motion: motion,
                                selected: i == selectedIndex,
                                focusNode: itemFocusNodes[i],
                                onSelect: () => onSelect(i),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (balanceSides)
                SizedBox(
                  width: sideWidth,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing,
                  ),
                )
              else
                trailing,
            ],
          ),
        ),
      );
    },
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.showLabel,
    required this.showIcon,
    required this.inRail,
    required this.glass,
    required this.motion,
    required this.selected,
    required this.onSelect,
    required this.focusNode,
    this.indicator,
  });

  final AppDestination destination;
  final bool showLabel, showIcon, inRail, glass, selected;
  final Duration motion;
  final VoidCallback onSelect;
  final FocusNode focusNode;
  final Widget? indicator;

  @override
  Widget build(BuildContext context) {
    final icon = selected
        ? destination.icon
        : destination.outlineIcon ?? destination.icon;
    return Semantics(
      selected: selected,
      child: Tooltip(
        message: destination.label,
        excludeFromSemantics: true,
        child: TextButton(
          focusNode: focusNode,
          onPressed: onSelect,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            animationDuration: motion,
            padding: WidgetStatePropertyAll(
              showLabel
                  ? EdgeInsetsDirectional.only(
                      start: showIcon ? 13 : 16,
                      end: 16,
                    )
                  : const EdgeInsets.symmetric(horizontal: 9),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => !selected && states.contains(WidgetState.focused)
                  ? AppColors.focusRing
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (states) => !selected && states.contains(WidgetState.focused)
                  ? AppColors.background
                  : selected || states.contains(WidgetState.hovered)
                  ? AppColors.textPrimary
                  : glass
                  ? NavigationGlass.foreground
                  : AppColors.textSecondary,
            ),
            side: WidgetStateProperty.resolveWith(
              (states) => selected && states.contains(WidgetState.focused)
                  ? const BorderSide(color: AppColors.focusRing, width: 2)
                  : BorderSide.none,
            ),
          ).withSelectionGradient(selected),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showIcon)
                    indicator ??
                        Icon(
                          icon,
                          size: showLabel ? 20 : 23,
                          semanticLabel: showLabel ? null : destination.label,
                        ),
                  if (showIcon && showLabel) const SizedBox(width: 8),
                  if (showLabel)
                    Text(
                      destination.label,
                      style: TextStyle(
                        fontSize: showIcon ? 17 : 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              if (selected && inRail)
                const Positioned(
                  bottom: -7,
                  child: SizedBox(
                    width: 14,
                    height: 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.selectionAccent,
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
