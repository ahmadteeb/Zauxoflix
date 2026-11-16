import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/theme/app_theme.dart';
import '../../data/backend/pairing_qr.dart';

/// Camera hardware and permission are checked only after the user chooses Scan.
final pairingCameraSupportedProvider = Provider<bool>(
  (ref) =>
      kIsWeb ||
      const [
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
      ].contains(defaultTargetPlatform),
);

final pairingScannerProvider =
    Provider<Future<String?> Function(BuildContext, Uri)>(
      (ref) =>
          (context, project) => Navigator.of(context).push<String>(
            MaterialPageRoute(
              builder: (_) => PairTvScanner(project: project),
              fullscreenDialog: true,
            ),
          ),
    );

class PairTvScanner extends StatefulWidget {
  const PairTvScanner({super.key, required this.project});
  final Uri project;
  @override
  State<PairTvScanner> createState() => _PairTvScannerState();
}

class _PairTvScannerState extends State<PairTvScanner> {
  bool _returned = false;
  String? _error;
  String? _lastInvalid;

  void _detect(BarcodeCapture capture) {
    if (_returned || !mounted) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      try {
        final code = PairingQr.parse(raw, widget.project);
        _returned = true;
        Navigator.pop(context, code);
        return;
      } on FormatException catch (error) {
        if (_lastInvalid != raw) {
          _lastInvalid = raw;
          setState(() => _error = error.message);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scan TV QR code')),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: MobileScanner(
              onDetect: _detect,
              // Without an external controller, the widget owns camera lifecycle/disposal.
              useAppLifecycleState: true,
              errorBuilder: (context, error) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.no_photography_outlined, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      error.errorCode == MobileScannerErrorCode.permissionDenied
                          ? 'Camera permission was denied. Allow camera access in device settings, or enter the TV code manually.'
                          : 'The camera is unavailable on this device. You can still enter the TV code manually.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Enter code manually'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Flexible(
            flex: 2,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Point your camera at the QR code on the TV. You’ll confirm the pairing before it signs in.',
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.keyboard_rounded),
                      label: const Text('Enter code instead'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
