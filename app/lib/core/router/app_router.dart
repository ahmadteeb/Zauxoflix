import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/backend/backend_providers.dart';
import '../../data/db/app_database.dart';
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
import '../../features/live/live_tv_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/remote/remote_control_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/shell/app_shell.dart';
import '../../features/source_setup/source_setup_screen.dart';
import '../../features/splash/splash_screen.dart';

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

final appRouterProvider = Provider<GoRouter>((ref) {
  // Bridge the active-source stream into a Listenable so GoRouter re-runs
  // redirect when the first source is added or the last one removed.
  final sourceState = ValueNotifier<AsyncValue<Source?>>(
    ref.read(activeSourceProvider),
  );
  // Bridge the auth session so redirect re-runs on login/logout/expiry.
  final authState = ValueNotifier<AuthState>(ref.read(authControllerProvider));
  ref
    ..onDispose(sourceState.dispose)
    ..onDispose(authState.dispose)
    ..listen(activeSourceProvider, (_, next) => sourceState.value = next)
    ..listen(authControllerProvider, (_, next) => authState.value = next);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: Listenable.merge([sourceState, authState]),
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // While the stored session restores, hold on the branded splash.
      final authed = authState.value;
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
      if (loc == '/setup' && sourceState.value.value != null) return '/home';

      if (loc == '/splash' ||
          loc == '/login' ||
          loc == '/register' ||
          loc == '/pair') {
        return '/home';
      }

      // A free account only needs a playlist to start watching.
      final async = sourceState.value;
      if (async.isLoading) return null;
      final hasSource = async.value != null;
      if (!hasSource && loc != '/setup') return '/setup';
      return null;
    },
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
        pageBuilder: (_, state) =>
            _fadePage(state, PlayerScreen(args: state.extra as PlayerArgs)),
      ),
      GoRoute(
        path: '/remote',
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
