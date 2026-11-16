import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/backend/pairing_models.dart';
import 'package:zauxoflix/data/backend/pairing_qr.dart';
import 'package:zauxoflix/data/backend/pairing_repository.dart';
import 'package:zauxoflix/features/settings/pair_tv_dialog.dart';
import 'package:zauxoflix/features/settings/pair_tv_scanner.dart';

class ClaimRepository implements PairingRepository {
  final claimed = <String>[];
  @override
  Future<String?> claim(String code) async {
    claimed.add(code);
    return 'Living room TV';
  }

  @override
  Future<PairingStart> start({String? deviceLabel}) =>
      throw UnimplementedError();
  @override
  Future<PairingPollResult> poll(String deviceSecret) =>
      throw UnimplementedError();
}

class CameraStub extends MobileScannerPlatform {
  CameraStub({this.denied = false});
  final bool denied;
  @override
  Stream<BarcodeCapture?> get barcodesStream => const Stream.empty();
  @override
  Stream<TorchState> get torchStateStream => const Stream.empty();
  @override
  Stream<double> get zoomScaleStateStream => const Stream.empty();
  @override
  Widget buildCameraView() => const ColoredBox(color: Colors.black);
  @override
  Future<MobileScannerViewAttributes> start(StartOptions startOptions) async {
    if (denied) {
      throw const MobileScannerException(
        errorCode: MobileScannerErrorCode.permissionDenied,
      );
    }
    return const MobileScannerViewAttributes(
      cameraDirection: CameraFacing.back,
      currentTorchMode: TorchState.unavailable,
      size: Size(640, 480),
    );
  }

  @override
  Future<void> stop() async {}

  @override
  Future<void> pause() async {}
  @override
  Future<void> dispose() async {}
}

void main() {
  final project = Uri.parse('https://test.supabase.co');
  testWidgets(
    'scanning fills the code but does not claim until the user confirms',
    (tester) async {
      final repository = ClaimRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pairingCameraSupportedProvider.overrideWithValue(true),
            pairingProjectProvider.overrideWithValue(project),
            pairingRepositoryProvider.overrideWithValue(repository),
            pairingScannerProvider.overrideWithValue((context, target) async {
              expect(target, project);
              return 'ABCDEFGH';
            }),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showPairTvDialog(context),
                  child: const Text('Open pairing'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open pairing'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Scan QR code'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'ABCDEFGH',
      );
      expect(repository.claimed, isEmpty);
      expect(
        find.textContaining('Check that this code matches your TV'),
        findsOneWidget,
      );
      await tester.tap(find.text('Pair'));
      await tester.pumpAndSettle();
      expect(repository.claimed, ['ABCDEFGH']);
    },
  );
  testWidgets('unsupported platforms retain manual code entry', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [pairingCameraSupportedProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showPairTvDialog(context),
                child: const Text('Open pairing'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open pairing'));
    await tester.pumpAndSettle();
    expect(find.text('Scan QR code'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });
  testWidgets(
    'scanner rejects other codes and returns a valid match only once',
    (tester) async {
      final old = MobileScannerPlatform.instance;
      final camera = CameraStub();
      MobileScannerPlatform.instance = camera;
      addTearDown(() => MobileScannerPlatform.instance = old);
      String? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  result = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PairTvScanner(project: project),
                    ),
                  );
                },
                child: const Text('Scan'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Scan'));
      await tester.pumpAndSettle();
      final detect = tester
          .widget<MobileScanner>(find.byType(MobileScanner))
          .onDetect!;
      detect(
        const BarcodeCapture(
          barcodes: [Barcode(rawValue: 'https://example.com')],
        ),
      );
      await tester.pump();
      expect(find.textContaining('not a Zauxoflix'), findsOneWidget);
      expect(result, isNull);
      final capture = BarcodeCapture(
        barcodes: [Barcode(rawValue: PairingQr.encode('ABCDEFGH', project))],
      );
      detect(capture);
      detect(capture);
      await tester.pumpAndSettle();
      expect(result, 'ABCDEFGH');
      expect(find.text('Scan'), findsOneWidget);
      expect(find.byType(MobileScanner), findsNothing);
    },
  );
  testWidgets('denied camera permission offers a manual-entry exit', (
    tester,
  ) async {
    final old = MobileScannerPlatform.instance;
    MobileScannerPlatform.instance = CameraStub(denied: true);
    addTearDown(() => MobileScannerPlatform.instance = old);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: PairTvScanner(project: project),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Camera permission was denied'), findsOneWidget);
    expect(find.text('Enter code manually'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
