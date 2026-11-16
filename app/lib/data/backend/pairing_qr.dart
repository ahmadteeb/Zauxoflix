/// The QR is a public pairing request, never a device secret or login session.
abstract final class PairingQr {
  static final _code = RegExp(r'^[A-HJ-NP-Z2-9]{8}$');

  static String encode(String code, Uri project) {
    if (!_code.hasMatch(code)) throw const FormatException('Invalid TV code.');
    return Uri(
      scheme: 'zauxoflix',
      host: 'pair',
      queryParameters: {'v': '1', 'code': code, 'instance': project.origin},
    ).toString();
  }

  static String parse(String raw, Uri project) {
    if (raw.length > 1024) {
      throw const FormatException(
        'This is not a Zauxoflix TV pairing QR code.',
      );
    }
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'zauxoflix' ||
        uri.host != 'pair' ||
        uri.path.isNotEmpty ||
        uri.hasPort ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.queryParametersAll.length != 3 ||
        uri.queryParametersAll.values.any((values) => values.length != 1) ||
        uri.queryParameters['v'] != '1' ||
        !_code.hasMatch(uri.queryParameters['code'] ?? '')) {
      throw const FormatException(
        'This is not a Zauxoflix TV pairing QR code.',
      );
    }
    if (uri.queryParameters['instance'] != project.origin) {
      throw const FormatException(
        'This TV uses a different Zauxoflix server. Use the same app deployment on both devices.',
      );
    }
    return uri.queryParameters['code']!;
  }
}
