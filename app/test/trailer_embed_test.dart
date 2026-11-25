import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zauxoflix/core/responsive/form_factor.dart';
import 'package:zauxoflix/features/details/trailer_screen.dart';

class _TestWebViews extends InAppWebViewPlatform {
  @override
  PlatformInAppWebViewWidget createPlatformInAppWebViewWidget(
    PlatformInAppWebViewWidgetCreationParams params,
  ) => _TestWebView(params);
}

class _TestWebView extends PlatformInAppWebViewWidget {
  _TestWebView(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox();
  @override
  T controllerFromPlatform<T>(PlatformInAppWebViewController controller) =>
      throw UnimplementedError();
  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('webos_plugin');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  testWidgets('TV layout embeds a supported WebView and offers remote play', (
    tester,
  ) async {
    final previous = InAppWebViewPlatform.instance;
    InAppWebViewPlatform.instance = _TestWebViews();
    if (previous != null) {
      addTearDown(() => InAppWebViewPlatform.instance = previous);
    }
    final container = ProviderContainer(
      overrides: [
        trailerEmbedAvailableProvider.overrideWith((_) async => true),
      ],
    );
    addTearDown(container.dispose);
    container.read(formFactorOverrideProvider.notifier).set(FormFactor.tv);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: TrailerScreen(video: 'BmllggGO4pM', title: 'The Gray Man'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InAppWebView), findsOneWidget);
    expect(find.text('Play trailer'), findsOneWidget);
  });

  test('LG trailer card receives the selected YouTube ID and title', () async {
    final launches = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      launches.add(call);
      return true;
    });
    expect(await launchWebOsTrailer('invalid/url', 'Other'), isFalse);
    expect(await launchWebOsTrailer('BmllggGO4pM', 'The Gray Man'), isTrue);
    expect(launches.single.method, 'app_manager/launch');
    expect(launches.single.arguments, {
      'id': 'com.flutter.app.zauxoflix.trailer',
      'params': {'video': 'BmllggGO4pM', 'title': 'The Gray Man'},
    });
  });

  test(
    'a missing LG trailer player allows the on-screen recovery flow',
    () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'APP_NOT_INSTALLED');
      });
      expect(await launchWebOsTrailer('BmllggGO4pM', 'The Gray Man'), isFalse);
    },
  );
}
