import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/widgets/app_background.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/backend/key_value_store.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/releases/release_repository.dart';
import 'package:zauxoflix/features/player/autoplay_preference.dart';
import 'package:zauxoflix/features/settings/settings_screen.dart';
import 'package:zauxoflix/features/settings/widgets/settings_navigation.dart';
import 'package:zauxoflix/features/settings/widgets/settings_section.dart';

const _viewer = BackendUser(
  id: 'demo',
  email: 'viewer@example.com',
  firstName: 'Demo',
  lastName: 'Viewer',
);

class _Auth extends AuthController {
  @override
  AuthState build() => const Authenticated(_viewer);
}

class _Layout extends FormFactorOverride {
  _Layout(this.initial);
  final FormFactor initial;
  @override
  FormFactor build() => initial;
}

class _LocalSettings implements KeyValueStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

class _Sync extends SyncController {
  Completer<bool> pending = Completer<bool>();
  @override
  SyncState build() => const SyncIdle();
  @override
  Future<bool> syncSource(Source source, {bool waitForGuide = true}) async {
    state = const SyncRunning('Loading movies…');
    final success = await pending.future;
    state = success ? const SyncSuccess() : const SyncFailure('Offline');
    pending = Completer<bool>();
    return success;
  }
}

class _Releases extends ReleaseRepository {
  @override
  Future<AppRelease?> latest() async =>
      AppRelease('v1.1.0', Version.parse('1.1.0'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fontDir = Platform.environment['SETTINGS_QA_FONT_DIR'];
  if (fontDir != null) {
    setUpAll(() async {
      for (final (family, paths) in [
        (
          'DM Sans',
          [
            'assets/fonts/DMSans-Regular.ttf',
            'assets/fonts/DMSans-Bold.ttf',
            'assets/fonts/DMSans-ExtraBold.ttf',
          ],
        ),
        ('MaterialIcons', ['$fontDir/materialicons-regular.otf']),
      ]) {
        final loader = FontLoader(family);
        for (final path in paths) {
          loader.addFont(File(path).readAsBytes().then(ByteData.sublistView));
        }
        await loader.load();
      }
      Directory('build/settings-previews').createSync(recursive: true);
    });
  }

  final navigation = find.byType(SettingsNavigation);
  Finder entry(String label) =>
      find.descendant(of: navigation, matching: find.text(label));

  for (final tv in [false, true]) {
    testWidgets('Settings sections and actions on ${tv ? 'TV' : 'phone'}', (
      tester,
    ) async {
      final previousTvBuild = kTvBuild;
      kTvBuild = tv;
      addTearDown(() => kTvBuild = previousTvBuild);
      tester.view.physicalSize = tv
          ? const Size(1280, 720)
          : const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final local = _LocalSettings();
      final sync = _Sync();
      final releases = _Releases();
      addTearDown(releases.dispose);
      const playlist = Source(
        id: 1,
        name: 'Living room playlist',
        sourceType: SourceType.xtream,
        serverUrl:
            'https://provider.example/library?token=sensitive-demo-value',
        username: 'demo',
        password: 'sensitive-demo-value',
      );
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (_, _) =>
                const Scaffold(body: AppBackground(child: SettingsScreen())),
          ),
          GoRoute(
            path: '/downloads',
            builder: (_, _) => const Scaffold(body: Text('Download library')),
          ),
        ],
      );
      addTearDown(router.dispose);
      final frame = GlobalKey();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_Auth.new),
            formFactorOverrideProvider.overrideWith(
              () => _Layout(tv ? FormFactor.tv : FormFactor.mobile),
            ),
            activeSourceProvider.overrideWith((ref) => Stream.value(playlist)),
            syncControllerProvider.overrideWith(() => sync),
            keyValueStoreProvider.overrideWithValue(local),
            releaseRepositoryProvider.overrideWithValue(releases),
            packageInfoProvider.overrideWith(
              (ref) async => PackageInfo(
                appName: 'Zauxoflix',
                packageName: 'app',
                version: '1.0.0',
                buildNumber: '8',
              ),
            ),
          ],
          child: RepaintBoundary(
            key: frame,
            child: MaterialApp.router(
              routerConfig: router,
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Future<void> capture(String section) async {
        if (fontDir == null) return;
        await tester.runAsync(() async {
          final boundary =
              frame.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'build/settings-previews/${tv ? 'tv' : 'phone'}-$section.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Future<void> select(String group) async {
        await tester.ensureVisible(entry(group));
        await tester.tap(entry(group));
        await tester.pumpAndSettle();
      }

      expect(find.text('Demo Viewer'), findsOneWidget);
      expect(entry('Downloads'), tv ? findsNothing : findsOneWidget);
      expect(
        find.ancestor(
          of: entry('Account'),
          matching: find.byWidgetPredicate(
            (widget) =>
                widget is Ink &&
                widget.decoration is ShapeDecoration &&
                (widget.decoration as ShapeDecoration).gradient ==
                    AppColors.selectionGradient,
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Sync now'), findsNothing);
      await capture('account');
      await tester.tap(find.text('Pair a TV'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      if (tv) {
        Focus.of(tester.element(entry('Account'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(find.text('Demo Viewer'), findsOneWidget);
        expect(
          FocusManager.instance.primaryFocus!.rect.contains(
            tester.getCenter(entry('Playlist')),
          ),
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        final panel = tester.getRect(find.byType(SettingsSection));
        expect(
          panel.contains(FocusManager.instance.primaryFocus!.rect.center),
          isTrue,
        );
      } else {
        await select('Playlist');
      }
      expect(find.text('Living room playlist'), findsOneWidget);
      expect(find.text('Never synced'), findsOneWidget);
      expect(find.textContaining('sensitive-demo-value'), findsNothing);
      await capture('playlist');
      await tester.tap(find.text('Sync now'));
      await tester.pump();
      expect(find.text('Loading movies…'), findsOneWidget);
      expect(
        tester
            .widget<SettingsAction>(
              find.widgetWithText(SettingsAction, 'Remove playlist'),
            )
            .onPressed,
        isNull,
      );
      sync.pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Sync failed: Offline'), findsOneWidget);
      await tester.tap(find.text('Sync now'));
      await tester.pump();
      sync.pending.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('Catalog up to date.'), findsOneWidget);
      await tester.ensureVisible(find.text('Remove playlist'));
      await tester.tap(find.text('Remove playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Remove playlist?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Living room playlist'), findsOneWidget);

      await select('Playback');
      final autoplay = find.byType(SwitchListTile);
      expect(tester.widget<SwitchListTile>(autoplay).value, isTrue);
      await tester.tap(find.text('Autoplay next episode'));
      await tester.pumpAndSettle();
      expect(local.values[autoplayKey(_viewer.id)], 'false');
      expect(tester.widget<SwitchListTile>(autoplay).value, isFalse);

      await select('App & updates');
      await tester.ensureVisible(find.text('Check for updates'));
      await tester.tap(find.text('Check for updates'));
      await tester.pumpAndSettle();
      expect(find.text('Update available: v1.1.0'), findsOneWidget);
      await select('Layout');
      final phoneOption = find.widgetWithText(SettingsAction, 'Phone');
      expect(tester.widget<SettingsAction>(phoneOption).selected, !tv);
      await select('App & updates');
      expect(find.text('Update available: v1.1.0'), findsOneWidget);
      if (!tv) {
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpAndSettle();
        expect(find.text('Update available: v1.1.0'), findsOneWidget);
        await select('Downloads');
        await tester.ensureVisible(find.text('Manage downloads'));
        await tester.tap(find.text('Manage downloads'));
        await tester.pumpAndSettle();
        expect(find.text('Download library'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
