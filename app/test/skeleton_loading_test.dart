import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/models/media_item.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/widgets/skeleton.dart';
import 'package:zauxoflix/features/home/widgets/hero_banner.dart';

void main() {
  for (final width in [320.0, 800.0, 1920.0]) {
    testWidgets('hero and channel skeletons fit width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HeroBanner(
                  loading: true,
                  item: const MediaItem(title: 'Not loaded yet'),
                  formFactor: width < 700 ? FormFactor.mobile : FormFactor.tv,
                ),
                const Expanded(child: ChannelListSkeleton()),
              ],
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Not loaded yet'), findsNothing);
      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(FilledButton), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('reduced motion displays static placeholders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SkeletonPulse(child: SkeletonBox(width: 100, height: 100)),
          ),
        ),
      ),
    );
    expect(find.byType(ShaderMask), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonBox), findsOneWidget);
  });
}
