import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:zauxoflix/data/backend/auth_models.dart';
import 'package:zauxoflix/data/backend/backend_providers.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/data/xtream/xtream_api.dart';
import 'package:zauxoflix/data/xtream/xtream_models.dart';

import 'package:zauxoflix/data/discovery/trakt_client.dart';
import 'package:zauxoflix/data/discovery/title_identity.dart';

const viewer = BackendUser(
  id: 'preview',
  email: 'viewer@example.invalid',
  firstName: 'Preview',
  lastName: 'Viewer',
);

class PreviewAuth extends AuthController {
  @override
  AuthState build() => const Authenticated(viewer);
  @override
  Future<void> logout() async {
    state = const Unauthenticated();
  }

  @override
  Future<void> login(String email, String password) async {
    state = const Authenticated(viewer);
  }
}

const previewShows = [
  TraktTitle(1, 'Severance', 2022, 'tt11280740', 95396),
  TraktTitle(2, 'Silo', 2023, 'tt14688458', 125988),
  TraktTitle(3, 'Dark', 2017, 'tt5753856', 70523),
  TraktTitle(4, 'The Office', 2001, 'tt0290978', null),
  TraktTitle(5, 'The Office', 2005, 'tt0386676', null),
];
const previewMovies = [
  TraktTitle(11, 'The Last Observatory', 2025, null, null),
  TraktTitle(12, 'Midnight Signal', 2024, null, null),
];

class PreviewDiscovery implements DiscoveryClient {
  @override
  Future<List<TraktTitle>> lookup(
    CatalogKind kind,
    String name,
    String? external,
  ) async => [
    for (final t in kind == CatalogKind.series ? previewShows : previewMovies)
      if (external == null
          ? discoveryName(t.name) == discoveryName(name)
          : t.hasExternal(external))
        t,
  ];
  @override
  Future<TitleDiscovery> details(CatalogKind kind, TraktTitle title) async =>
      TitleDiscovery(
        title,
        8.4,
        {
          if (title.id == 1) 'en': 'xEQP4VVuyrY',
          if (title.id == 12) 'en': '00000000000',
        },
        [
          for (final t
              in kind == CatalogKind.series
                  ? previewShows.take(3)
                  : previewMovies)
            if (t.id != title.id) t,
        ],
      );
}

class PreviewApi extends XtreamApi {
  PreviewApi(String base)
    : super(
        XtreamCredentials(
          serverUrl: base,
          username: 'preview',
          password: 'preview',
        ),
      );
  @override
  String seriesEpisodeUrl(int episodeId, String? containerExtension) =>
      '${credentials.serverUrl}/sample.mp4';
  @override
  Future<XtreamVodInfo> vodInfo(int id) async => XtreamVodInfo(
    plot: id == 11
        ? 'At a mountain observatory, an astronomer picks up a transmission that should have fallen silent years ago.'
        : 'A night operator follows a signal through a sleeping city.',
    backdrop: '${credentials.serverUrl}/art/$id',
    genre: 'Science fiction',
    releaseDate: id == 11 ? '2025' : '2024',
  );
  @override
  Future<XtreamSeriesInfo> seriesInfo(int id) async => XtreamSeriesInfo(
    genre: id == 4 ? 'Comedy' : 'Drama · Mystery',
    plot: switch (id) {
      1 =>
        'At Lumon Industries, Mark lives two lives. On the office floor, he has no memory of the person he becomes when he leaves.',
      2 =>
        'Deep underground, the residents of a silo begin to question the rules that keep their world sealed.',
      3 =>
        'A disappearance draws four families into a mystery spanning generations.',
      _ => 'Life at a regional paper company.',
    },
    seasons: {
      for (final s in [1, 2])
        s: [
          for (final e in [1, 2, 3])
            XtreamEpisode(
              id: id * 100 + s * 10 + e,
              title: 'Playback sample $e',
              season: s,
              episodeNum: e,
              containerExtension: 'mp4',
            ),
        ],
    },
  );
}

/// Original fixture artwork. All sample titles render offline.
Future<List<int>> artwork(int id) async {
  final recorder = ui.PictureRecorder();
  final c = Canvas(recorder);
  const bounds = Rect.fromLTWH(0, 0, 960, 640);
  final p = Paint();
  void rect(double x, double y, double w, double h, int color) => c.drawRect(
    Rect.fromLTWH(x, y, w, h),
    p
      ..shader = null
      ..color = Color(color),
  );
  void shape(List<Offset> points, int color) => c.drawPath(
    Path()..addPolygon(points, true),
    p
      ..shader = null
      ..color = Color(color),
  );
  final colors = switch (id) {
    1 => [const Color(0xff799795), const Color(0xff26444a)],
    2 => [const Color(0xffc59a60), const Color(0xff292d2a)],
    3 => [const Color(0xff728775), const Color(0xff122323)],
    11 => [const Color(0xff1f2458), const Color(0xffe69e78)],
    _ => [const Color(0xff1c3049), const Color(0xff8e555b)],
  };
  c.drawRect(
    bounds,
    p..shader = ui.Gradient.linear(bounds.topLeft, bounds.bottomRight, colors),
  );
  if (id == 1) {
    const vanishing = Offset(605, 284);
    for (final corner in [
      bounds.topLeft,
      bounds.topRight,
      bounds.bottomLeft,
      bounds.bottomRight,
    ]) {
      c.drawLine(
        corner,
        vanishing,
        p
          ..shader = null
          ..color = const Color(0xffc3d7c9)
          ..strokeWidth = 2,
      );
    }
    for (final t in [0.0, .27, .48, .64, .76, .85]) {
      Offset at(Offset a) => Offset.lerp(a, vanishing, t)!;
      shape([
        at(const Offset(392, 0)),
        at(const Offset(658, 0)),
        at(const Offset(642, 16)),
        at(const Offset(397, 16)),
      ], 0xffe2efdf);
      shape([
        at(const Offset(93, 93)),
        at(const Offset(172, 121)),
        at(const Offset(172, 491)),
        at(const Offset(93, 540)),
      ], 0xff38575c);
    }
    rect(580, 257, 32, 55, 0xffc3d3bc);
  } else if (id == 2) {
    for (var i = 7; i > 0; i--) {
      final radius = i * 59.0;
      c.drawCircle(
        const Offset(570, 300),
        radius,
        p
          ..shader = null
          ..color = Color.lerp(colors[0], colors[1], i.isOdd ? 0.59 : 0.8)!,
      );
      c.drawArc(
        Rect.fromCircle(center: const Offset(570, 300), radius: radius),
        -.9,
        2.4,
        false,
        p
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xffe8b673),
      );
      p.style = PaintingStyle.fill;
    }
  } else if (id == 3) {
    final random = math.Random(31);
    for (var layer = 0; layer < 3; layer++) {
      for (var i = 0; i < 45; i++) {
        final x = random.nextDouble() * 1000;
        final base = 420.0 + layer * 100;
        final height = 100 + random.nextDouble() * 280;
        shape([
          Offset(x - 40, base),
          Offset(x, base - height),
          Offset(x + 40, base),
        ], [0xff47635c, 0xff314c45, 0xff20342e][layer]);
      }
    }
  } else {
    final random = math.Random(id);
    for (var i = 0; i < 120; i++) {
      c.drawCircle(
        Offset(random.nextDouble() * 960, random.nextDouble() * 435),
        random.nextDouble() * 1.8,
        p
          ..shader = null
          ..color = const Color(0xffe6dee5),
      );
    }
    if (id == 11) {
      shape([
        const Offset(0, 560),
        const Offset(290, 385),
        const Offset(482, 471),
        const Offset(712, 408),
        const Offset(960, 500),
        bounds.bottomRight,
        bounds.bottomLeft,
      ], 0xff353448);
      c.drawArc(
        const Rect.fromLTWH(470, 290, 222, 233),
        math.pi,
        math.pi,
        true,
        p..color = const Color(0xffd8cebd),
      );
      rect(470, 407, 222, 96, 0xff414354);
      shape([
        const Offset(561, 292),
        const Offset(587, 290),
        const Offset(631, 406),
        const Offset(601, 406),
      ], 0xff474654);
    } else {
      for (var i = 0; i < 30; i++) {
        final height = random.nextDouble() * 150 + 50;
        rect(i * 34, 510 - height, 31, height + 130, 0xff223042);
      }
      rect(573, 170, 5, 293, 0xff151f32);
      c.drawCircle(
        const Offset(575, 168),
        6,
        p..color = const Color(0xfff29478),
      );
    }
  }
  final picture = recorder.endRecording();
  final image = await picture.toImage(960, 640);
  final bytes = (await image.toByteData(
    format: ui.ImageByteFormat.png,
  ))!.buffer.asUint8List();
  image.dispose();
  picture.dispose();
  return bytes;
}

Future<int> seedPreview(AppDatabase db, String base) async {
  final now = DateTime.now();
  final source = await db.insertSource(
    SourcesCompanion.insert(
      name: 'Sample catalog',
      serverUrl: base,
      username: 'preview',
      password: 'preview',
      lastSyncAt: Value(now),
    ),
  );
  await db.replaceMovies(source, [
    for (final t in previewMovies)
      MoviesCompanion.insert(
        sourceId: source,
        streamId: t.id,
        name: t.name,
        icon: Value('$base/art/${t.id}'),
        releaseYear: Value(t.year),
        rating: const Value(4.2),
        ratingScale: const Value(5),
        streamUrl: Value('$base/sample.mp4'),
        containerExtension: const Value('mp4'),
        addedAt: Value(now.subtract(Duration(days: t.id))),
      ),
  ]);
  await db.replaceSeries(source, [
    for (final t in previewShows.take(4))
      SeriesItemsCompanion.insert(
        sourceId: source,
        seriesId: t.id,
        name: t.name,
        cover: Value('$base/art/${t.id}'),
        releaseYear: Value(t.id == 4 ? null : t.year),
        lastModifiedAt: Value(now.subtract(Duration(days: t.id))),
      ),
  ]);
  return source;
}
