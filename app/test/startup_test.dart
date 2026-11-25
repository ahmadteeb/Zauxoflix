import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zauxoflix/main.dart' as app;

void main() {
  testWidgets(
    'startup configuration or plugin failures show a visible message',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
            (_) async => throw MissingPluginException(),
          );
      await tester.runAsync(app.main);
      await tester.pump();
      const configured =
          String.fromEnvironment('SUPABASE_URL') != '' &&
          String.fromEnvironment('SUPABASE_ANON_KEY') != '';
      expect(
        find.textContaining(
          configured
              ? 'Zauxoflix could not start (secure session storage: '
                    'MissingPluginException)'
              : 'Supabase is not configured.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      if (configured) {
        await tester.runAsync(() => Supabase.instance.dispose());
      }
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    },
  );
}
