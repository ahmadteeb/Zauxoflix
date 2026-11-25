import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../shell/navigation_glass.dart';
import 'settings_section.dart';

enum SettingsGroup {
  account('Account', Icons.person_outline_rounded),
  playlist('Playlist', Icons.playlist_play_rounded),
  playback('Playback', Icons.play_circle_outline_rounded),
  downloads('Downloads', Icons.download_outlined),
  layout('Layout', Icons.devices_outlined),
  about('App & updates', Icons.info_outline_rounded);

  const SettingsGroup(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SettingsNavigation extends StatelessWidget {
  const SettingsNavigation({
    super.key,
    required this.groups,
    required this.selected,
    required this.onSelect,
    required this.wide,
  });

  final List<SettingsGroup> groups;
  final SettingsGroup selected;
  final ValueChanged<SettingsGroup> onSelect;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: wide
          ? NavigationGlass(
              radius: 22,
              outlined: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
                child: Column(
                  children: [
                    for (final group in groups)
                      SettingsAction(
                        icon: group.icon,
                        title: group.label,
                        selected: selected == group,
                        onPressed: () => onSelect(group),
                      ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const gap = 7.0;
                final scale = MediaQuery.textScalerOf(context).scale(14);
                final columns = scale > 20 || constraints.maxWidth < 310
                    ? 2
                    : constraints.maxWidth >= 680
                    ? groups.length
                    : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * gap) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final group in groups)
                      SizedBox(
                        width: width,
                        child: Semantics(
                          selected: selected == group,
                          child: TextButton(
                            onPressed: () => onSelect(group),
                            style:
                                settingsButtonStyle(
                                  context,
                                  selected: selected == group,
                                ).copyWith(
                                  minimumSize: const WidgetStatePropertyAll(
                                    Size.fromHeight(64),
                                  ),
                                  padding: const WidgetStatePropertyAll(
                                    EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 7,
                                    ),
                                  ),
                                ),
                            child: Column(
                              children: [
                                Icon(
                                  group.icon,
                                  size: 20,
                                  color: selected == group
                                      ? AppColors.selectionAccent
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  group.label,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }
}
