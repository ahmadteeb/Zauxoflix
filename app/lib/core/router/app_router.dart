import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/backend/backend_providers.dart';
import '../../data/providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/pairing_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/browse/browse_screen.dart';
import '../../features/details/movie_details_screen.dart';
import '../../features/details/series_details_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/guide/epg_grid_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/widgets/home_remote_navigation.dart';
import '../../features/home/widgets/poster_card.dart';
import '../../features/shell/destinations.dart';
import '../../features/live/live_tv_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/remote/remote_control_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/source_setup/source_setup_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../app_platform.dart';

/// Plain crossfade — used for full-screen swaps (auth, splash, player) where
/// a directional slide would imply a spatial relationship that doesn't exist.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 240),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (context, animation, _, child) =>
          MediaQuery.disableAnimationsOf(context)
          ? child
          : FadeTransition(
              opacity: CurveTween(
                curve: Curves.easeOutCubic,
              ).animate(animation),
              child: child,
            ),
    );

/// Fade + a short upward drift — details screens "rise" over the catalog.
CustomTransitionPage<void> _risePage(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (context, animation, _, child) {
        if (MediaQuery.disableAnimationsOf(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

/// Root navigator for app-level overlays.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final tvBackDispatcherProvider = Provider<TvBackButtonDispatcher>((ref) {
  final back = TvBackButtonDispatcher(
    ref.watch(appRouterProvider),
    confirmExitAtHome: isWebOsPlatform,
  );
  ref.onDispose(back.dispose);
  return back;
});

class TvBackButtonDispatcher extends RootBackButtonDispatcher {
  TvBackButtonDispatcher(this.router, {this.confirmExitAtHome = false}) {
    router.routerDelegate.addListener(_rememberTab);
  }

  final GoRouter router;
  final bool confirmExitAtHome;
  final _tabs = <String>['/home'];
  bool _handling = false;
  Timer? _backBounce;

  void _rememberTab() {
    final configuration = router.routerDelegate.currentConfiguration;
    if (configuration.isEmpty) return;
    final path = configuration.uri.path;
    if (path == '/home' || path == '/login' || path == '/setup') {
      _tabs
        ..clear()
        ..add('/home');
    } else if (appDestinations.any((d) => d.path == path) &&
        _tabs.last != path) {
      _tabs.remove(path);
      _tabs.add(path);
    }
  }

  void dispose() {
    _backBounce?.cancel();
    router.routerDelegate.removeListener(_rememberTab);
  }

  Future<void> _confirmExit(BuildContext context) async {
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Exit Zauxoflix?'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    if (exit == true) await SystemNavigator.pop();
  }

  @override
  Future<bool> didPopRoute() async {
    if (_handling || _backBounce?.isActive == true) return true;
    _handling = true;
    try {
      if (confirmExitAtHome) {
        // A remote press can be reported through both the keyboard and the
        // platform navigation channel. Apply it to one navigation level.
        _backBounce = Timer(const Duration(milliseconds: 180), () {});
        if (PosterCard.dismissVisiblePreview()) return true;
      }
      if (await super.didPopRoute()) return true;
      final path = router.state.uri.path;
      if (path == '/pair' || path == '/register') {
        router.go('/login');
      } else if (path == '/home') {
        if (confirmExitAtHome) {
          final context = router.routerDelegate.navigatorKey.currentContext;
          if (context != null && context.mounted) {
            unawaited(_confirmExit(context));
          }
        } else {
          HomeRemoteNavigation.enterFromTop(FocusManager.instance.rootScope);
        }
      } else if (appDestinations.any((d) => d.path == path)) {
        if (_tabs.length > 1 && _tabs.last == path) _tabs.removeLast();
        router.go(_tabs.last);
      }
      return true;
    } finally {
      _handling = false;
    }
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  String? redirectFor(String loc) {
    // While the stored session restores, hold on the branded splash.
    final authed = ref.read(authControllerProvider);
    if (authed is AuthLoading) return loc == '/splash' ? null : '/splash';

    if (authed is! Authenticated) {
      // /pair is reachable pre-auth: the TV shows a code and polls for a
      // session, so it must live on the unauthenticated side of the gate.
      const preAuth = {'/login', '/register', '/pair'};
      return preAuth.contains(loc) ? null : '/login';
    }
    // A local empty source is inconclusive until account restoration finishes.
    if (authed.sourceRestoring || authed.sourceRestoreFailed) {
      return loc == '/home' ? null : '/home';
    }

    if (loc == '/splash' ||
        loc == '/login' ||
        loc == '/register' ||
        loc == '/pair') {
      return '/home';
    }

    // A free account only needs a playlist to start watching.
    final async = ref.read(activeSourceProvider);
    if (async.isLoading) return null;
    final hasSource = async.value != null;
    if (!hasSource && loc != '/setup') return '/setup';
    return null;
  }

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    redirect: (_, state) => redirectFor(state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (_, state) => _fadePage(state, const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, state) => _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: '/pair',
        pageBuilder: (_, state) => _fadePage(state, const PairingScreen()),
      ),
      GoRoute(
        path: '/setup',
        pageBuilder: (_, state) => _fadePage(state, const SourceSetupScreen()),
      ),
      GoRoute(
        path: '/movie/:id',
        pageBuilder: (_, state) => _risePage(
          state,
          MovieDetailsScreen(streamId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/series/:id',
        pageBuilder: (_, state) => _risePage(
          state,
          SeriesDetailsScreen(seriesId: int.parse(state.pathParameters['id']!)),
        ),
      ),
      GoRoute(
        path: '/player',
        redirect: (_, state) => state.extra is PlayerArgs ? null : '/home',
        pageBuilder: (_, state) =>
            _fadePage(state, PlayerScreen(args: state.extra as PlayerArgs)),
      ),
      GoRoute(
        path: '/remote',
        redirect: (_, state) =>
            state.extra is RemoteControlArgs ? null : '/home',
        pageBuilder: (_, state) => _fadePage(
          state,
          RemoteControlScreen(args: state.extra! as RemoteControlArgs),
        ),
      ),
      GoRoute(
        path: '/guide',
        pageBuilder: (_, state) => _risePage(state, const EpgGridScreen()),
      ),
      // Not .indexedStack: its default container keeps inactive branches
      // focusable, so D-pad traversal (and the shell's focus restore) could
      // land on invisible offstage screens. This container excludes them.
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            _BranchStack(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/live', builder: (_, _) => const LiveTvScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/movies',
                builder: (_, _) => const BrowseScreen.movies(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/series',
                builder: (_, _) => const BrowseScreen.series(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/search', builder: (_, _) => const SearchScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/downloads',
                builder: (_, _) => const DownloadsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Re-parsing platform history loses transient player arguments and the
  // pending fullscreen pop result. Only navigate when an access gate changes
  // where the viewer belongs. Incoming navigations use the same checks above.
  void checkAccess() {
    if (router.routerDelegate.currentConfiguration.isEmpty) return;
    final target = redirectFor(router.state.matchedLocation);
    if (target != null) router.go(target);
  }

  ref.listen(activeSourceProvider, (_, _) => checkAccess());
  ref.listen(authControllerProvider, (_, _) => checkAccess());
  ref.onDispose(router.dispose);
  return router;
});

/// go_router's default IndexedStack branch container, plus [ExcludeFocus] so
/// inactive (invisible) branches can never hold or receive focus.
class _BranchStack extends StatelessWidget {
  const _BranchStack({required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        for (var i = 0; i < children.length; i++)
          ExcludeFocus(
            excluding: i != currentIndex,
            child: Offstage(
              offstage: i != currentIndex,
              child: TickerMode(enabled: i == currentIndex, child: children[i]),
            ),
          ),
      ],
    );
  }
}
