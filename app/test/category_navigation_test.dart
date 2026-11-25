import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/core/theme/app_theme.dart';
import 'package:zauxoflix/data/db/app_database.dart';
import 'package:zauxoflix/features/browse/category_dropdown.dart';

final _categories = [
  for (final (index, name) in ['Action', 'Comedy', 'Drama'].indexed)
    Category(
      sourceId: 1,
      kind: CatalogKind.vod,
      categoryId: '$index',
      name: name,
    ),
];

Widget _host(
  FormFactor form,
  List<Category> categories,
  ValueChanged<String?> onChanged, {
  String? selectedId,
}) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: CategoryDropdown(
          formFactor: form,
          categories: categories,
          selectedId: selectedId,
          onChanged: onChanged,
          gutter: 0,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('phone category sheet supports search, recovery and dismissal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final picked = <String?>[];
    await tester.pumpWidget(
      _host(FormFactor.mobile, _categories, picked.add, selectedId: '0'),
    );
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'thriller');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    expect(find.text('No matching categories'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    expect(find.text('Comedy'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'DRA');
    await tester.pumpAndSettle();
    expect(find.text('Comedy'), findsNothing);
    await tester.tap(find.text('Drama'));
    await tester.pumpAndSettle();
    tester.view.resetViewInsets();
    expect(picked, ['2']);

    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close categories'));
    await tester.pumpAndSettle();
    expect(picked, ['2']);
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('All categories'));
    await tester.pumpAndSettle();
    expect(picked, ['2', null]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TV reopens at a distant category and moves with the D-pad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final categories = [
      for (var i = 0; i < 40; i++)
        Category(
          sourceId: 1,
          kind: CatalogKind.series,
          categoryId: '$i',
          name: 'Category $i',
        ),
    ];
    final picked = <String?>[];
    await tester.pumpWidget(
      _host(FormFactor.tv, categories, picked.add, selectedId: '31'),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final trigger = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    final dialog = tester.getRect(find.byType(Dialog));
    expect(
      dialog.contains(FocusManager.instance.primaryFocus!.rect.center),
      isTrue,
    );
    final selectedOption = find.descendant(
      of: find.byType(Dialog),
      matching: find.text('Category 31'),
    );
    expect(
      FocusManager.instance.primaryFocus!.rect.contains(
        tester.getCenter(selectedOption),
      ),
      isTrue,
    );
    final highlight = tester.widget<Ink>(
      find.ancestor(of: selectedOption, matching: find.byType(Ink)),
    );
    final decoration = highlight.decoration! as ShapeDecoration;
    expect(decoration.gradient, AppColors.selectionGradient);
    expect(
      (decoration.shape as OutlinedBorder).side.color,
      AppColors.focusRing,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(picked, ['32']);
    expect(FocusManager.instance.primaryFocus, trigger);
    expect(tester.takeException(), isNull);
  });
}
