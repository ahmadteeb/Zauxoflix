// Run explicitly to refresh README images using synthetic account/provider data.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/data/releases/release_repository.dart';
import 'package:zauxoflix/data/xtream/xtream_models.dart';
import 'package:zauxoflix/features/settings/iptv_info_dialog.dart';
import 'package:zauxoflix/features/settings/settings_screen.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';

class DemoReleases extends ReleaseRepository {
  @override
  Future<AppRelease?> latest() async =>
      AppRelease('v1.1.0', Version.parse('1.1.0'));
}

class DemoAuth extends AuthController {
  @override
  AuthState build() => const Authenticated(
    BackendUser(
      id: 'demo',
      email: 'viewer@example.com',
      firstName: 'Demo',
      lastName: 'Viewer',
    ),
  );
}

void main() {
  testWidgets('capture Settings and IPTV information', (tester) async {
    await tester.runAsync(() async {
      final fonts = Platform.environment['ZAUXOFLIX_FONT_DIR'];
      if (fonts == null) {
        throw StateError(
          'Set ZAUXOFLIX_FONT_DIR to the Flutter SDK cache/artifacts/material_fonts directory.',
        );
      }
      final roboto = FontLoader('Roboto');
      for (final name in [
        'Roboto-Regular.ttf',
        'Roboto-Medium.ttf',
        'Roboto-Bold.ttf',
      ]) {
        roboto.addFont(
          Future.value(
            ByteData.sublistView(await File('$fonts/$name').readAsBytes()),
          ),
        );
      }
      await roboto.load();
      await (FontLoader('MaterialIcons')..addFont(
            Future.value(
              ByteData.sublistView(
                await File('$fonts/MaterialIcons-Regular.otf').readAsBytes(),
              ),
            ),
          ))
          .load();
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1120, 1600);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const source = Source(
      id: 1,
      name: 'My IPTV provider',
      sourceType: SourceType.xtream,
      serverUrl: 'https://iptv.example.com',
      username: 'demo_viewer',
      password: 'demo-only',
    );
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(DemoAuth.new),
        activeSourceProvider.overrideWith((ref) => Stream.value(source)),
        packageInfoProvider.overrideWith(
          (ref) async => PackageInfo(
            appName: 'Zauxoflix',
            packageName: 'app',
            version: '1.0.0',
            buildNumber: '1',
          ),
        ),
        releaseRepositoryProvider.overrideWith((ref) => DemoReleases()),
        iptvInfoProvider(source).overrideWith(
          (ref) async => XtreamUserInfo(
            authenticated: true,
            status: 'Active',
            expiresAt: DateTime(2027, 1, 31),
            maxConnections: 2,
            activeConnections: 1,
            isTrial: false,
            outputFormats: const ['ts', 'm3u8', 'rtmp'],
          ),
        ),
      ],
    );
    final key = GlobalKey();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: key,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark.copyWith(
              textTheme: AppTheme.dark.textTheme.apply(fontFamily: 'Roboto'),
              primaryTextTheme: AppTheme.dark.primaryTextTheme.apply(
                fontFamily: 'Roboto',
              ),
              filledButtonTheme: FilledButtonThemeData(
                style: AppTheme.dark.filledButtonTheme.style!.copyWith(
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            home: const Scaffold(
              backgroundColor: AppColors.background,
              body: SettingsScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.ensureVisible(find.text('Check for updates'));
    await tester.tap(find.text('Check for updates'));
    await tester.pump();
    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    Future<void> capture(String name) async {
      expect(tester.takeException(), isNull);
      await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '../screenshots/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/images/github-mark.png'),
        key.currentContext!,
      ),
    );
    await tester.pump();
    await capture('settings');
    tester.view.physicalSize = const Size(1120, 900);
    await tester.pump();
    await tester.tap(find.text('IPTV information'));
    await tester.pumpAndSettle();
    await capture('iptv-information');
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
  });
}
