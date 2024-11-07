import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';
import 'package:camelus/main.dart' as app;

main() {
  //IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  group('end-to-end test', () {
    testWidgets('test onboarding, terms acceptance', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('camelus'), findsOneWidget);

      // check agb link
      expect(find.text('terms and conditions'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'next'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Please read and accept the terms and conditions first'),
          findsOneWidget);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'next'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(NostrOnboarding), findsNothing);

      //await tester.pumpAndSettle(const Duration(minutes: 1));
    });
  });
}
