import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/backend/pairing_models.dart';
import 'package:zauxoflix/data/backend/pairing_repository.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/providers.dart';
import 'package:zauxoflix/features/auth/login_screen.dart';
import 'package:zauxoflix/features/auth/pairing_screen.dart';
import 'package:zauxoflix/main.dart';

/// Hands out a fixed code, then reports the code claimed on the first poll.
class _FakePairingRepository implements PairingRepository {
  _FakePairingRepository({this.claimImmediately = true});

  final bool claimImmediately;
  int polls = 0;

  @override
  Future<PairingStart> start({String? deviceLabel}) async => PairingStart(
    code: 'WXYZ789A',
    deviceSecret: 'secret-xyz',
    expiresAt: DateTime.now().add(const Duration(minutes: 10)),
    pollInterval: const Duration(milliseconds: 10),
  );

  @override
  Future<String?> claim(String code) async => throw UnimplementedError();

  @override
  Future<PairingPollResult> poll(String deviceSecret) async {
    polls++;
    if (!claimImmediately && polls < 2) return const PairingPending();
    return PairingClaimed(
      const LoginResult(
        user: BackendUser(id: 'u1', email: 'v@x.com'),
      ),
    );
  }
}

/// Starts signed-out and adopts the paired session without touching the network
/// provisioning that the real controller runs.
class _StubAuthController extends AuthController {
  @override
  AuthState build() => const Unauthenticated();

  @override
  Future<void> completePairing(LoginResult result) async {
    state = Authenticated(result.user);
  }
}

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(375, 812),
    const Size(844, 390),
    const Size(1920, 1080),
  ]) {
    testWidgets('QR stays beside its code at $size with large text', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_StubAuthController.new),
            pairingProjectProvider.overrideWithValue(
              Uri.parse('https://test.supabase.co'),
            ),
            pairingRepositoryProvider.overrideWithValue(
              _FakePairingRepository(claimImmediately: false),
            ),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const PairingScreen(),
          ),
        ),
      );
      await tester.pump();
      final qr = tester.getRect(find.byType(QrImageView));
      final code = Rect.fromPoints(
        tester.getTopLeft(find.text('WXYZ789A')),
        tester.getBottomRight(find.text('WXYZ789A')),
      );
      expect(qr.right, lessThan(code.left));
      expect(code.center.dy, inInclusiveRange(qr.top, qr.bottom));
      expect(qr.width, greaterThanOrEqualTo(112));
      expect(code.right, lessThan(size.width));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }
  testWidgets(
    'the pairing screen shows a code and adopts the claimed session',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(_StubAuthController.new),
          pairingProjectProvider.overrideWithValue(
            Uri.parse('https://test.supabase.co'),
          ),
          pairingRepositoryProvider.overrideWithValue(_FakePairingRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PairingScreen()),
        ),
      );

      // start() resolves and the code is shown.
      await tester.pump();
      expect(find.text('WXYZ789A'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(container.read(authControllerProvider), isA<Unauthenticated>());

      // The poll fires after its interval and the claim adopts the session.
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump();
      expect(container.read(authControllerProvider), isA<Authenticated>());

      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('login screen routes to the pairing screen while signed out', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());

    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authControllerProvider.overrideWith(_StubAuthController.new),
        pairingProjectProvider.overrideWithValue(
          Uri.parse('https://test.supabase.co'),
        ),
        pairingRepositoryProvider.overrideWithValue(
          _FakePairingRepository(claimImmediately: false),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ZauxoflixApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Pair a TV with a code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(PairingScreen), findsOneWidget);
    expect(find.text('WXYZ789A'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}
