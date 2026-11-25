import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/core/widgets/catalog_row_card.dart';
import 'package:zauxoflix/features/home/widgets/catalog_card_preview.dart';
import 'package:zauxoflix/features/home/widgets/content_rail.dart';
import 'package:zauxoflix/features/home/widgets/poster_card.dart';

void main() {
  const item = MediaItem(
    title: 'القضاء · Yargı',
    type: MediaType.series,
    id: 7,
  );
  const data = (
    image: null,
    summary: 'Two families face a difficult decision.',
    metadata: '★ 8.2',
  );
  Widget host(Widget child, {void Function()? lookup, bool rtl = false}) =>
      ProviderScope(
        overrides: [
          catalogCardPreviewProvider((MediaType.series, 7)).overrideWith((
            _,
          ) async {
            lookup?.call();
            return data;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Directionality(
              textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
              child: Center(child: child),
            ),
          ),
        ),
      );

  testWidgets(
    'title survives missing art, dwell is lazy, persistent and dismissible',
    (tester) async {
      var reads = 0, selected = 0;
      await tester.pumpWidget(
        host(
          PosterCard(item: item, width: 174, onSelect: () => selected++),
          lookup: () => reads++,
        ),
      );
      expect(find.text(item.title), findsOneWidget);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(PosterCard)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(reads, 0);
      await mouse.moveTo(Offset.zero);
      await tester.pump(const Duration(milliseconds: 500));
      expect(reads, 0);
      await mouse.moveTo(tester.getCenter(find.byType(PosterCard)));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pump();
      expect(find.text(data.summary), findsOneWidget);
      await tester.pump(const Duration(seconds: 8));
      expect(find.text(data.summary), findsOneWidget);
      expect(selected, 0);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text(data.summary), findsNothing);
      expect(find.text(item.title), findsOneWidget);
      await tester.tap(find.text(item.title));
      expect(selected, 1);
      await mouse.removePointer();
    },
  );

  testWidgets(
    'arrow focus reveals details, Enter selects one title, I opens the preview',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        host(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PosterCard(item: item, width: 160, onSelect: () => selected++),
              PosterCard(
                item: const MediaItem(title: 'Second'),
                width: 160,
                onSelect: () => selected += 10,
              ),
            ],
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(find.text(data.summary), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyI);
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPreviewDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(CatalogPreviewDialog), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(selected, 10);
    },
  );

  testWidgets(
    'touch preview offers details while the card still plays the next episode',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const next = MediaItem(
        title: 'القضاء · Yargı',
        subtitle: 'S1 E4 — Circle Narrowing',
        badge: 'Next · S1 E4',
        type: MediaType.series,
        id: 7,
        continueWatching: true,
      );
      int plays = 0, details = 0, removes = 0;
      await tester.pumpWidget(
        host(
          PosterCard(
            item: next,
            width: 250,
            wide: true,
            onSelect: () => plays++,
            onDetails: () => details++,
            onRemove: () => removes++,
          ),
          rtl: true,
        ),
      );
      expect(find.text('Circle Narrowing'), findsOneWidget);
      await tester.tap(find.byTooltip('Preview ${next.title}'));
      await tester.pumpAndSettle();
      expect(find.text(next.subtitle), findsOneWidget);
      await tester.tap(find.text('View details'));
      await tester.pumpAndSettle();
      expect(details, 1);
      expect(plays, 0);
      await tester.tap(find.text(next.title));
      await tester.longPress(find.text(next.title));
      expect((plays, removes), (1, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('TV arrows move by card and a held OK opens its preview', (
    tester,
  ) async {
    String? selected;
    Widget card(String title) => PosterCard(
      item: MediaItem(title: title),
      width: 125,
      tvNavigation: true,
      onSelect: () => selected = title,
    );
    await tester.pumpWidget(
      host(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [card('One'), card('Two')],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [card('Three'), card('Four')],
            ),
          ],
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(selected, 'Four');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogPreviewDialog), findsOneWidget);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    expect(selected, 'Four');
  });

  testWidgets(
    'rail paging reveals later titles and can return to the first title',
    (tester) async {
      await tester.pumpWidget(
        host(
          ContentRail(
            title: 'Movies',
            formFactor: FormFactor.desktop,
            items: List.generate(
              22,
              (i) => MediaItem(id: i, title: 'Movie $i'),
            ),
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('More in Movies'));
      await tester.pumpAndSettle();
      final rail = tester.state<ScrollableState>(find.byType(Scrollable).first);
      expect(rail.position.pixels, greaterThan(0));
      await tester.tap(find.byTooltip('Previous in Movies'));
      await tester.pumpAndSettle();
      expect(rail.position.pixels, 0);
    },
  );

  testWidgets(
    'hovering an episode in the player drawer reveals its plot without tuning',
    (tester) async {
      var opens = 0;
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 320,
            child: CatalogRowCard(
              title: 'Circle Narrowing',
              description: data.summary,
              previewDescription: true,
              icon: Icons.movie_outlined,
              onSelect: () => opens++,
            ),
          ),
        ),
      );
      expect(find.text(data.summary), findsNothing);
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.byType(CatalogRowCard)));
      await tester.pumpAndSettle();
      expect(find.text(data.summary), findsOneWidget);
      expect(opens, 0);
      await mouse.removePointer();
    },
  );
}
