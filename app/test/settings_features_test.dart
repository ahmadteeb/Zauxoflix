import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/auth_repository.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/features/settings/account_dialogs.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/widgets/external_link.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/releases/release_repository.dart';
import 'package:zauxoflix/data/xtream/xtream_models.dart';
import 'package:zauxoflix/features/settings/iptv_info_dialog.dart';
import 'package:zauxoflix/features/settings/widgets/app_info_section.dart';

class FakeReleases extends ReleaseRepository {
  int checks = 0;
  @override
  Future<AppRelease?> latest() async {
    checks++;
    return AppRelease('v1.1.0', Version.parse('1.1.0'));
  }
}

const source = Source(
  id: 1,
  name: 'Provider',
  sourceType: SourceType.xtream,
  serverUrl: 'https://secret:password@provider.example/path?password=secret',
  username: 'viewer',
  password: 'never-show-this',
);

void main() {
  test('provider summaries never display URL credentials or query strings', () {
    expect(sourceOrigin(source.serverUrl), 'https://provider.example');
  });
  test(
    'provider metadata tolerates panel types and ignores non-string formats',
    () {
      final info = XtreamUserInfo.fromJson({
        'user_info': {
          'auth': '1',
          'status': 'Active',
          'active_cons': '1',
          'max_connections': '2',
          'is_trial': '0',
          'created_at': '1700000000',
          'allowed_output_formats': ['ts', 'm3u8', 7],
        },
      });
      expect(info.authenticated, isTrue);
      expect(info.activeConnections, 1);
      expect(info.maxConnections, 2);
      expect(info.isTrial, isFalse);
      expect(info.createdAt, isNotNull);
      expect(info.outputFormats, ['ts', 'm3u8']);
    },
  );
  testWidgets(
    'Settings compares versions on demand and opens the exact manual release',
    (tester) async {
      final repository = FakeReleases();
      final opened = <Uri>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            packageInfoProvider.overrideWith(
              (ref) async => PackageInfo(
                appName: 'Zauxoflix',
                packageName: 'app',
                version: '1.0.0',
                buildNumber: '9',
              ),
            ),
            releaseRepositoryProvider.overrideWithValue(repository),
            externalLinkLauncherProvider.overrideWithValue((uri) async {
              opened.add(uri);
              return true;
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(
              body: SingleChildScrollView(child: AppInfoSection()),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Version 1.0.0 (build 9)'), findsOneWidget);
      expect(repository.checks, 0);
      await tester.tap(find.text('Check for updates'));
      await tester.pump();
      expect(find.text('Update available: v1.1.0'), findsOneWidget);
      await tester.tap(find.text('Download v1.1.0'));
      await tester.pump();
      expect(
        opened.single.toString(),
        'https://github.com/ahmadteeb/Zauxoflix/releases/tag/v1.1.0',
      );
      expect(find.text('Developed by Ahmad El-Khatib'), findsOneWidget);
      repository.dispose();
    },
  );
  testWidgets(
    'IPTV account details show provider data without revealing a password',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            iptvInfoProvider(source).overrideWith(
              (ref) async => XtreamUserInfo(
                authenticated: true,
                status: 'Active',
                expiresAt: DateTime(2027, 1, 31),
                maxConnections: 2,
                activeConnections: 1,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showIptvInfoDialog(context, source),
                  child: const Text('Details'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('2027-01-31'), findsOneWidget);
      expect(find.text('viewer'), findsOneWidget);
      expect(find.textContaining('never-show-this'), findsNothing);
      expect(find.text('https://provider.example'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
    },
  );

  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets('IPTV details remain scrollable with large text at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            iptvInfoProvider(source).overrideWith(
              (ref) async => XtreamUserInfo(
                authenticated: true,
                status: 'Active',
                expiresAt: DateTime(2027, 1, 31),
                maxConnections: 2,
                activeConnections: 1,
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showIptvInfoDialog(context, source),
                  child: const Text('Details'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final done = find.text('Done');
      expect(tester.getRect(done).bottom, lessThan(size.height));
      await tester.ensureVisible(find.text('https://provider.example'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('never-show-this'), findsNothing);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  }
  testWidgets('browser failure gives a copyable fallback for TVs', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          externalLinkLauncherProvider.overrideWithValue((uri) async => false),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) => TextButton(
                onPressed: () => openExternalLink(
                  context,
                  ref,
                  ReleaseRepository.releasesPage,
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Open on another device'), findsOneWidget);
    expect(
      find.text(ReleaseRepository.releasesPage.toString()),
      findsOneWidget,
    );
  });
  testWidgets('closing an in-flight profile dialog ignores late save errors', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(() => WaitingProfile(pending)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showEditProfileDialog(
                  context,
                  const BackendUser(id: 'test', email: 'viewer@example.com'),
                ),
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    pending.completeError(const AuthException('network_error', 'Offline'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class WaitingProfile extends AuthController {
  WaitingProfile(this.pending);
  final Completer<void> pending;
  @override
  AuthState build() => const Unauthenticated();
  @override
  Future<void> updateProfile({
    required String? firstName,
    required String? lastName,
    required String? phone,
  }) => pending.future;
}
