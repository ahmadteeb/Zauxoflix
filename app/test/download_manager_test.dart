import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/downloads/download_manager.dart';
import 'package:zauxoflix/data/downloads/download_storage.dart';
import 'package:zauxoflix/data/providers.dart';

void main() {
  test(
    'known download size is rejected before writing past the free-space reserve',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'Fixture',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final temp = await Directory.systemTemp.createTemp('download-storage-');
      addTearDown(() => temp.delete(recursive: true));
      final path = '${temp.path}/fixture.mp4';
      await db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.movie,
          itemId: 4,
          title: 'Large fixture',
          filePath: path,
          status: DownloadStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );
      final storage = _FixedStorage(0);
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          downloadStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var requests = 0;
      server.listen((request) async {
        requests++;
        request.response.contentLength = 64;
        request.response.add(List.filled(64, 42));
        await request.response.close();
      });
      final manager = container.read(downloadManagerProvider.notifier);
      Future<void> start() => manager.start(
        sourceId: 1,
        kind: WatchKind.movie,
        itemId: 4,
        url: 'http://127.0.0.1:${server.port}/fixture',
        title: 'Large fixture',
      );
      await expectLater(start(), throwsA(isA<InsufficientDownloadSpace>()));
      expect(requests, 0);

      storage.bytes = DownloadStorage.minimumFreeMiB * 1024 * 1024 + 32;
      await start();
      final rejected = await db
          .watchDownload(1, WatchKind.movie, 4)
          .firstWhere((item) => item?.status == DownloadStatus.noSpace)
          .timeout(const Duration(seconds: 5));
      expect(rejected?.totalBytes, isNull);
      expect(requests, 1);
      expect(File(path).existsSync(), isFalse);
      expect(File('$path.part').existsSync(), isFalse);
    },
  );

  test(
    'a failed transfer stays visible and resumes an existing partial file',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.insertSource(
        SourcesCompanion.insert(
          name: 'Fixture',
          serverUrl: '',
          username: '',
          password: '',
        ),
      );
      final temp = await Directory.systemTemp.createTemp('download-manager-');
      addTearDown(() => temp.delete(recursive: true));
      final path = '${temp.path}/legacy.mp4';
      final partial = File('$path.part');
      await partial.writeAsBytes([10, 20]);
      await db.upsertDownload(
        DownloadsCompanion.insert(
          sourceId: 1,
          kind: WatchKind.movie,
          itemId: 33,
          title: 'Fixture',
          filePath: path,
          status: DownloadStatus.downloading,
          createdAt: DateTime.now(),
        ),
      );
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          downloadStorageProvider.overrideWithValue(
            _FixedStorage(1024 * 1024 * 1024),
          ),
        ],
      );
      addTearDown(container.dispose);
      final manager = container.read(downloadManagerProvider.notifier);
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var available = false;
      final ranges = <String?>[];
      server.listen((request) async {
        ranges.add(request.headers.value(HttpHeaders.rangeHeader));
        final response = request.response;
        if (!available) {
          response.statusCode = HttpStatus.forbidden;
        } else {
          response.statusCode = HttpStatus.partialContent;
          response.headers.set(HttpHeaders.contentRangeHeader, 'bytes 2-3/4');
          response.contentLength = 2;
          response.add([30, 40]);
        }
        await response.close();
      });
      Future<void> start() => manager.start(
        sourceId: 1,
        kind: WatchKind.movie,
        itemId: 33,
        url: 'http://127.0.0.1:${server.port}/fixture',
        title: 'Fixture',
      );
      Future<List<DownloadItem>> waitFor(DownloadStatus status) => db
          .watchDownloads(1)
          .firstWhere((rows) => rows.singleOrNull?.status == status)
          .timeout(const Duration(seconds: 5));

      await start();
      await waitFor(DownloadStatus.failed);
      expect(await partial.readAsBytes(), [10, 20]);
      expect(await manager.localPath(1, WatchKind.movie, 33), isNull);

      available = true;
      await Future.wait([start(), start()]);
      final completed = (await waitFor(DownloadStatus.done)).single;
      expect(ranges, ['bytes=2-', 'bytes=2-']);
      expect(completed.filePath, path);
      expect(completed.totalBytes, 4);
      expect(await File(path).readAsBytes(), [10, 20, 30, 40]);
      expect(partial.existsSync(), isFalse);
      expect(await manager.localPath(1, WatchKind.movie, 33), path);
    },
  );
}

class _FixedStorage extends DownloadStorage {
  _FixedStorage(this.bytes);

  int bytes;

  @override
  Future<int?> freeBytes(String directory) async => bytes;
}
