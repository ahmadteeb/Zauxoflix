import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/backend/pairing_qr.dart';

void main() {
  final project = Uri.parse('https://test.supabase.co');
  test('QR round-trips the public code and project only', () {
    final encoded = PairingQr.encode('ABCDEFGH', project);
    final uri = Uri.parse(encoded);
    expect(PairingQr.parse(encoded, project), 'ABCDEFGH');
    expect(uri.queryParameters.keys.toSet(), {'v', 'code', 'instance'});
    expect(encoded, isNot(contains('deviceSecret')));
    expect(encoded, isNot(contains('token')));
  });
  test(
    'foreign project, arbitrary URLs, versions and duplicated fields are rejected',
    () {
      final encoded = PairingQr.encode('ABCDEFGH', project);
      for (final value in [
        'https://example.com/?code=ABCDEFGH',
        'ABCDEFGH',
        '$encoded&code=BBBBBBBB',
        '$encoded&deviceSecret=secret',
        encoded.replaceFirst('v=1', 'v=2'),
        encoded.replaceFirst('ABCDEFGH', '12345678'),
        '$encoded#fragment',
        'x' * 1025,
      ]) {
        expect(() => PairingQr.parse(value, project), throwsFormatException);
      }
      expect(
        () => PairingQr.parse(encoded, Uri.parse('https://other.supabase.co')),
        throwsFormatException,
      );
    },
  );
}
