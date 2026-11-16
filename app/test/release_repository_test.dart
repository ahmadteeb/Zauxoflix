import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/releases/release_repository.dart';

class ReleaseAdapter implements HttpClientAdapter {
  ReleaseAdapter(this.body, [this.status = 200]);
  final Object body;
  final int status;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    expect(
      options.uri.toString(),
      'https://api.github.com/repos/ahmadteeb/Zauxoflix/releases/latest',
    );
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ReleaseRepository repository(Object json, [int status = 200]) {
  final dio = Dio()..httpClientAdapter = ReleaseAdapter(json, status);
  final repository = ReleaseRepository(dio: dio);
  addTearDown(repository.dispose);
  return repository;
}

void main() {
  test(
    'release tags compare numerically and open only this repository',
    () async {
      final release = (await repository({
        'tag_name': 'v1.10.0',
        'html_url': 'https://untrusted.example',
      }).latest())!;
      expect(release.isNewerThan('1.9.0'), isTrue);
      expect(release.isNewerThan('1.10.0+7'), isFalse);
      expect(release.isNewerThan('2.0.0'), isFalse);
      expect(
        release.page.toString(),
        'https://github.com/ahmadteeb/Zauxoflix/releases/tag/v1.10.0',
      );
    },
  );
  test('404 is a no-public-release state', () async {
    expect(await repository({'message': 'Not Found'}, 404).latest(), isNull);
  });
  test(
    'draft and prerelease versions are not offered as stable updates',
    () async {
      expect(
        await repository({'tag_name': 'v2.0.0', 'draft': true}).latest(),
        isNull,
      );
      expect(await repository({'tag_name': 'v2.0.0-rc.1'}).latest(), isNull);
    },
  );
  test('invalid tags and rate limits are actionable errors', () async {
    await expectLater(
      repository({'tag_name': 'nightly'}).latest(),
      throwsA(
        isA<ReleaseCheckException>().having(
          (error) => error.message,
          'message',
          contains('version tag'),
        ),
      ),
    );
    await expectLater(
      repository({}, 403).latest(),
      throwsA(
        isA<ReleaseCheckException>().having(
          (error) => error.message,
          'message',
          contains('request limit'),
        ),
      ),
    );
  });
}
