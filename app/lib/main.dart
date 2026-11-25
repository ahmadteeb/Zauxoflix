import 'dart:async';
import 'dart:io';
import 'features/player/episode_buffer.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage_webos/flutter_secure_storage_webos.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/input/input_modality.dart';
import 'core/tv/tv_back_button.dart';
import 'core/app_platform.dart';
import 'core/responsive/form_factor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'data/backend/backend_providers.dart';
import 'data/backend/device_identity.dart';
import 'data/backend/key_value_store.dart';
import 'data/backend/secure_session_storage.dart';
import 'data/db/app_database.dart';
import 'features/player/webos_video_player.dart';
import 'features/remote/remote_playback.dart';

String _startupStage = 'configuration';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(const [
      'DM Sans',
    ], await rootBundle.loadString('assets/fonts/OFL-DM-Sans.txt'));
    yield LicenseEntryWithLineBreaks(
      const ['IBM Plex Sans Arabic'],
      await rootBundle.loadString('assets/fonts/OFL-IBM-Plex-Sans-Arabic.txt'),
    );
  });
  runApp(_startupScreen());
  try {
    final app = await _initializeApplication().timeout(
      const Duration(seconds: 30),
    );
    runApp(app);
  } catch (error) {
    // Do not print exception text: it can contain backend URLs or session data.
    debugPrint('[Startup] $_startupStage failed: ${error.runtimeType}');
    runApp(_startupScreen(error: '$_startupStage: ${error.runtimeType}'));
  }
}

Widget _startupScreen({String? error}) => MaterialApp(
  theme: AppTheme.dark,
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: error == null
            ? const CircularProgressIndicator()
            : Text(
                'Zauxoflix could not start ($error). Restart the app. '
                'If this continues, collect the TV startup logs.',
                textAlign: TextAlign.center,
              ),
      ),
    ),
  ),
);

Future<Widget> _initializeApplication() async {
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    return MaterialApp(
      theme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Supabase is not configured. Build with SUPABASE_URL and SUPABASE_ANON_KEY.',
            ),
          ),
        ),
      ),
    );
  }
  _startupStage = 'secure session storage';
  // Select the LG adapter before Supabase reads its persisted session. The
  // default adapter uses a different method channel from the webOS runner.
  if (isWebOsPlatform) FlutterSecureStorageWebos.registerWith();
  final store = SecureKeyValueStore();
  await Supabase.initialize(
    url: url,
    publishableKey: key,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(store, url),
      // Embedded TV sign-in uses pairing rather than desktop app links.
      detectSessionInUri: !isTizenPlatform && !isWebOsPlatform,
    ),
  );
  if (!isTizenPlatform && !isWebOsPlatform) {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }
  // Desktop window control — needed for the player's fullscreen toggle.
  if (isDesktopPlatform) {
    _startupStage = 'desktop window initialization';
    await windowManager.ensureInitialized();
  }
  // Resolve TV-ness before anything reads kTvBuild (layout + input modality).
  _startupStage = 'platform initialization';
  await detectTvDevice();
  InputModality.attach();
  // Use libmdk for IPTV containers that AVPlayer cannot reliably open.
  // TV runtimes must retain their platform-specific player implementations.
  if (isWebOsPlatform) {
    WebOsVideoPlayer.registerWith();
    configureWebOsSqlite();
  } else if (isFvpPlatform) {
    fvp.registerWith(
      options: {
        'platforms': ['linux', 'windows', 'macos', 'ios', 'android'],
        // Keep a short in-place HTTP reconnect to preserve buffered playback.
        'player': <String, String>{
          'avio.reconnect_delay_max': '2',
          'avio.reconnect_max_retries': '1',
          'avio.reconnect_delay_total_max': '3',
        },
      },
    );
  }

  // Resolve the secure store and stable device id before the app reads any
  // provider that depends on them (auth restore runs on first frame).
  _startupStage = 'device identity storage';
  await store.delete('auth.accessToken');
  await store.delete('auth.refreshToken');
  final device = await loadOrCreateDeviceIdentity(store);
  if (isWebOsPlatform) debugPrint('[Startup] webOS secure storage ready');

  return ProviderScope(
    overrides: [
      episodeBufferEnabledProvider.overrideWithValue(
        isFvpPlatform && !Platform.isMacOS,
      ),
      keyValueStoreProvider.overrideWithValue(store),
      deviceIdentityProvider.overrideWithValue(device),
    ],
    child: const ZauxoflixApp(),
  );
}

class ZauxoflixApp extends ConsumerWidget {
  const ZauxoflixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final tvBack = kTvBuild ? ref.watch(tvBackDispatcherProvider) : null;
    // Instantiates the listener for playback commands relayed from the
    // account's other devices; without this watch nothing subscribes.
    ref.watch(remotePlaybackProvider);
    return MaterialApp.router(
      title: 'Zauxoflix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      onNavigationNotification: kTvBuild && Platform.isAndroid
          ? (_) {
              SystemNavigator.setFrameworkHandlesBack(true);
              return true;
            }
          : null,
      routerConfig: tvBack == null
          ? router
          : RouterConfig(
              routeInformationProvider: router.routeInformationProvider,
              routeInformationParser: router.routeInformationParser,
              routerDelegate: router.routerDelegate,
              backButtonDispatcher: tvBack,
            ),
      builder: (context, child) => Listener(
        // Any pointer interaction switches autofocus behavior back to
        // pointer-first; see InputModality.
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => InputModality.notePointer(),
        // Tapping outside a focused text field dismisses the keyboard. The
        // gesture arena keeps this from firing when the tap lands on the
        // field itself or on any tappable control.
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            final focus = FocusManager.instance.primaryFocus;
            if (focus?.context?.findAncestorWidgetOfExactType<EditableText>()
                case EditableText()) {
              focus!.unfocus();
            }
          },
          child: Shortcuts(
            shortcuts: {
              if (tvBack?.confirmExitAtHome == true)
                const SingleActivator(lgRemoteBackKey, includeRepeats: false):
                    const NavigateBackIntent(),
              if (kTvBuild)
                const SingleActivator(
                  LogicalKeyboardKey.colorF0Red,
                  includeRepeats: false,
                ): const NavigateBackIntent(),
              const SingleActivator(
                LogicalKeyboardKey.escape,
                includeRepeats: false,
              ): const NavigateBackIntent(),
              const SingleActivator(
                LogicalKeyboardKey.goBack,
                includeRepeats: false,
              ): const NavigateBackIntent(),
              const SingleActivator(
                LogicalKeyboardKey.browserBack,
                includeRepeats: false,
              ): const NavigateBackIntent(),
            },
            child: Actions(
              actions: {
                NavigateBackIntent: CallbackAction<NavigateBackIntent>(
                  onInvoke: (_) {
                    if (tvBack != null) {
                      unawaited(tvBack.didPopRoute());
                    } else if (router.canPop()) {
                      router.pop();
                    }
                    return null;
                  },
                ),
              },
              child: AppBackground(child: child!),
            ),
          ),
        ),
      ),
    );
  }
}
