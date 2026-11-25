import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/widgets/media_artwork.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

MediaArtwork cover(String? url, {Widget? alternate}) => MediaArtwork(
  url: url,
  title: 'ليلة في عمّان',
  kind: ArtworkKind.episode,
  width: 120,
  height: 76,
  cacheWidth: 240,
  icon: Icons.movie_outlined,
  progress: .4,
  fallbackArtwork: alternate,
);

// Drive the same decoded image stream the cached-image widget listens to. This
// exercises the real loading, failure and success paths without network timing.
Future<Completer<ImageInfo>> imageStream(String url) async {
  final provider = ResizeImage.resizeIfNeeded(
    240,
    null,
    CachedNetworkImageProvider(url),
  );
  final key = await provider.obtainKey(ImageConfiguration.empty);
  final frame = Completer<ImageInfo>();
  PaintingBinding.instance.imageCache.putIfAbsent(
    key,
    () => OneFrameImageStreamCompleter(frame.future),
  );
  return frame;
}

void main() {
  testWidgets(
    'empty URLs render the episode name and preserve watch progress',
    (tester) async {
      for (final url in [null, '   ']) {
        await tester.pumpWidget(host(cover(url)));
        final art = tester.widget<TitleArtwork>(find.byType(TitleArtwork));
        expect(art.kind, ArtworkKind.episode);
        expect(find.text('ليلة في عمّان', findRichText: true), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          .4,
        );
      }
    },
  );

  testWidgets(
    'broken artwork falls through the alternate to the named cover, then recovers',
    (tester) async {
      const first = 'https://cdn.example/first.jpg';
      const backup = 'https://cdn.example/backup.jpg';
      const fixed = 'https://cdn.example/fixed.jpg';
      final broken = await imageStream(first);
      final second = await imageStream(backup);
      await tester.pumpWidget(host(cover(first, alternate: cover(backup))));
      expect(find.text('ليلة في عمّان', findRichText: true), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsOneWidget);
      broken.completeError(StateError('Missing first image'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CachedNetworkImage), findsNWidgets(2));
      second.completeError(StateError('Missing alternate'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('ليلة في عمّان', findRichText: true), findsOneWidget);
      final recovered = await imageStream(fixed);
      await tester.pumpWidget(host(cover(fixed)));
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawColor(Colors.green, BlendMode.src);
      final picture = recorder.endRecording();
      recovered.complete(ImageInfo(image: picture.toImageSync(2, 2)));
      picture.dispose();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(TitleArtwork), findsNothing);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    },
  );

  testWidgets('a poster fits a long word without splitting its last letter', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MediaArtwork(
          title: 'Severance',
          kind: ArtworkKind.series,
          width: 262,
          height: 394,
          cacheWidth: 524,
          icon: Icons.tv,
        ),
      ),
    );
    final finder = find.text('Severance', findRichText: true);
    final rich = tester.widget<RichText>(finder);
    final text = TextPainter(
      text: rich.text,
      textDirection: TextDirection.ltr,
      textScaler: rich.textScaler,
    )..layout(maxWidth: tester.getSize(finder).width);
    expect(text.computeLineMetrics().length, 1);
    text.dispose();
  });

  testWidgets(
    'compact RTL lettering and captioned covers retain one full title',
    (tester) async {
      const name = 'قناة الأردن الرياضية الدولية';
      for (final hasCaption in [true, false]) {
        await tester.pumpWidget(
          host(
            Directionality(
              textDirection: TextDirection.rtl,
              child: SizedBox(
                width: 34,
                height: 26,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    TitleArtwork(
                      title: name,
                      kind: ArtworkKind.live,
                      hasCaption: hasCaption,
                    ),
                    if (hasCaption)
                      const Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        expect(find.text(name, findRichText: true), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
