import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/input/input_modality.dart';
import 'core/responsive/form_factor.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_background.dart';
import 'data/backend/backend_providers.dart';
import 'data/backend/device_identity.dart';
import 'data/backend/key_value_store.dart';
import 'data/backend/secure_session_storage.dart';
import 'features/remote/remote_playback.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty) {
    runApp(
      MaterialApp(
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
      ),
    );
    return;
  }
  final store = SecureKeyValueStore();
  await Supabase.initialize(
    url: url,
    publishableKey: key,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(store, url),
    ),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));
  // Desktop window control — needed for the player's fullscreen toggle.
  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
  }
  // Resolve TV-ness before anything reads kTvBuild (layout + input modality).
  await detectTvDevice();
  InputModality.attach();
  // fvp backs video_player on desktop; Android/iOS keep the native players.
  fvp.registerWith(
    options: {
      'platforms': ['linux', 'windows', 'macos'],
      'video.decoders': ['auto', 'av1', 'hevc', 'h264', 'h265'],
      'video.hwdec': [
        'auto',
        'dxva2',
        'd3d11va',
        'd3d11',
        'd3d9',
        'nvdec',
        'nvdec_hevc',
        'nvdec_h264',
        'nvdec_h265',
      ],
    },
  );

  // Resolve the secure store and stable device id before the app reads any
  // provider that depends on them (auth restore runs on first frame).
  await store.delete('auth.accessToken');
  await store.delete('auth.refreshToken');
  final device = await loadOrCreateDeviceIdentity(store);

  runApp(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        deviceIdentityProvider.overrideWithValue(device),
      ],
      child: const ZauxoflixApp(),
    ),
  );
}

class ZauxoflixApp extends ConsumerWidget {
  const ZauxoflixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Instantiates the listener for playback commands relayed from the
    // account's other devices; without this watch nothing subscribes.
    ref.watch(remotePlaybackProvider);
    return MaterialApp.router(
      title: 'Zauxoflix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
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
            shortcuts: const {
              SingleActivator(LogicalKeyboardKey.escape): _PopIntent(),
              SingleActivator(LogicalKeyboardKey.goBack): _PopIntent(),
            },
            child: Actions(
              actions: {
                _PopIntent: CallbackAction<_PopIntent>(
                  onInvoke: (_) {
                    if (router.canPop()) router.pop();
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

class _PopIntent extends Intent {
  const _PopIntent();
}
