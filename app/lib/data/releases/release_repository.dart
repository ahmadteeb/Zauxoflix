import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);
final releaseRepositoryProvider = Provider<ReleaseRepository>((ref) {
  final repository = ReleaseRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

class AppRelease {
  const AppRelease(this.tag, this.version);
  final String tag;
  final Version version;
  Uri get page =>
      Uri.https('github.com', '/ahmadteeb/Zauxoflix/releases/tag/$tag');
  bool isNewerThan(String installed) =>
      version > Version.parse(installed.replaceFirst(RegExp(r'^[vV]'), ''));
}

class ReleaseCheckException implements Exception {
  const ReleaseCheckException(this.message);
  final String message;
}

class ReleaseRepository {
  ReleaseRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 15),
              headers: {
                'Accept': 'application/vnd.github+json',
                'User-Agent': 'Zauxoflix',
              },
            ),
          );
  final Dio _dio;
  static final releasesPage = Uri.https(
    'github.com',
    '/ahmadteeb/Zauxoflix/releases',
  );
  static final developerPage = Uri.https('github.com', '/ahmadteeb');

  Future<AppRelease?> latest() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://api.github.com/repos/ahmadteeb/Zauxoflix/releases/latest',
      );
      final json = response.data;
      if (json == null || json['draft'] == true || json['prerelease'] == true) {
        return null;
      }
      final tag = json['tag_name'];
      if (tag is! String) throw const FormatException('Missing release tag');
      final version = Version.parse(tag.replaceFirst(RegExp(r'^[vV]'), ''));
      if (version.isPreRelease) return null;
      return AppRelease(tag, version);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) return null;
      if (error.response?.statusCode == 403 ||
          error.response?.statusCode == 429) {
        throw const ReleaseCheckException(
          'GitHub’s request limit was reached. Try again later or open Releases.',
        );
      }
      throw const ReleaseCheckException(
        'Could not check for updates. Check your connection and try again.',
      );
    } on FormatException {
      throw const ReleaseCheckException(
        'The latest release has an unsupported version tag. Open Releases to check manually.',
      );
    }
  }

  void dispose() => _dio.close();
}
