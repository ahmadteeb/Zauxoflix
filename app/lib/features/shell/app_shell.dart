import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/responsive/form_factor.dart';
import '../../core/theme/app_theme.dart';
import '../remote/cast_button.dart';
import 'destinations.dart';
import 'top_nav_bar.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formFactor = formFactorOf(context, ref);
    final mobileDestinations = [
      ...appDestinations.take(4),
      appDestinations.last,
    ];
    final mobileIndex = mobileDestinations.indexWhere(
      (d) => d.path == appDestinations[navigationShell.currentIndex].path,
    );

    return switch (formFactor) {
      FormFactor.mobile => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'ZAUXOFLIX',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Search',
                      onPressed: () => context.go('/search'),
                      icon: const Icon(Icons.search_rounded),
                    ),
                    IconButton(
                      tooltip: 'Downloads',
                      onPressed: () => context.go('/downloads'),
                      icon: const Icon(Icons.download_rounded),
                    ),
                    const CastButton(),
                  ],
                ),
              ),
              Expanded(
                child: _BranchFade(
                  index: navigationShell.currentIndex,
                  child: navigationShell,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: mobileIndex < 0 ? 0 : mobileIndex,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          onDestinationSelected: (index) =>
              _goBranch(appDestinations.indexOf(mobileDestinations[index])),
          destinations: [
            for (final d in mobileDestinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      ),
      // Tablet, desktop and TV share the Netflix-style top nav layout.
      _ => _TopNavShell(navigationShell: navigationShell, onSelect: _goBranch),
    };
  }
}

class _TopNavShell extends StatefulWidget {
  const _TopNavShell({required this.navigationShell, required this.onSelect});

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onSelect;

  @override
  State<_TopNavShell> createState() => _TopNavShellState();
}

class _TopNavShellState extends State<_TopNavShell> {
  late final List<FocusNode> _navItemNodes = [
    for (final d in appDestinations) FocusNode(debugLabel: 'nav:${d.label}'),
  ];
  final _navScope = FocusScopeNode(debugLabel: 'topNavScope');
  final _contentScope = FocusScopeNode(debugLabel: 'contentScope');

  @override
  void dispose() {
    for (final node in _navItemNodes) {
      node.dispose();
    }
    _navScope.dispose();
    _contentScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: Actions(
                actions: {
                  DirectionalFocusIntent: _ContentEdgeDirectionalAction(
                    () => _navItemNodes[widget.navigationShell.currentIndex],
                  ),
                },
                child: FocusScope(
                  node: _contentScope,
                  child: FocusTraversalGroup(
                    child: _BranchFade(
                      index: widget.navigationShell.currentIndex,
                      child: widget.navigationShell,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // Own scope so Left/Right traversal stays inside the bar instead
              // of leaking into the content scope's node.
              child: Actions(
                actions: {
                  DirectionalFocusIntent: _NavBarDirectionalAction(
                    _contentScope,
                  ),
                },
                child: FocusScope(
                  node: _navScope,
                  child: TopNavBar(
                    selectedIndex: widget.navigationShell.currentIndex,
                    onSelect: widget.onSelect,
                    itemFocusNodes: _navItemNodes,
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

/// Fades the shell content back in whenever the active branch changes —
/// IndexedStack itself swaps instantly, which reads as a jarring hard cut.
class _BranchFade extends StatefulWidget {
  const _BranchFade({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_BranchFade> createState() => _BranchFadeState();
}

class _BranchFadeState extends State<_BranchFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );

  @override
  void didUpdateWidget(_BranchFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeOut).animate(_controller),
      child: widget.child,
    );
  }
}

/// D-pad handling while focus is in the top nav bar: Down returns focus to
/// the content (restoring its last focused item), other directions traverse
/// within the bar's scope.
class _NavBarDirectionalAction extends Action<DirectionalFocusIntent> {
  _NavBarDirectionalAction(this.contentScope);

  final FocusScopeNode contentScope;

  @override
  Object? invoke(DirectionalFocusIntent intent) {
    if (intent.direction == TraversalDirection.down) {
      contentScope.requestFocus();
      // Nothing to restore (first visit, or the branch changed and the old
      // focus sits in a now focus-excluded branch) — walk into the topmost
      // focusable instead of parking focus on the scope itself.
      if (contentScope.focusedChild == null) {
        contentScope.focusInDirection(TraversalDirection.down);
      }
      return null;
    }
    primaryFocus?.focusInDirection(intent.direction);
    return null;
  }
}

/// Each shell branch is a Navigator with its own FocusScope, so geometric
/// traversal can never leave it. When Up fails at the content's top edge,
/// hand focus to the nav bar explicitly.
class _ContentEdgeDirectionalAction extends Action<DirectionalFocusIntent> {
  _ContentEdgeDirectionalAction(this.selectedNavNode);

  final FocusNode Function() selectedNavNode;

  @override
  Object? invoke(DirectionalFocusIntent intent) {
    final node = primaryFocus;
    if (node == null) return null;
    final moved = node.focusInDirection(intent.direction);
    if (!moved && intent.direction == TraversalDirection.up) {
      selectedNavNode().requestFocus();
    }
    return null;
  }
}
