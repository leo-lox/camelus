import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('NostrOnboarding widget test', (WidgetTester tester) async {
    // Wrap the widget with ProviderScope

    await tester.pumpWidget(createWidgetUnderTest(child: NostrOnboarding()));

    // Rest of your test...
    expect(find.text('camelus'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'join the conversation'),
        findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'login'), findsOneWidget);
  });

  testWidgets('terms not accepted', (WidgetTester tester) async {
    await tester
        .pumpWidget(createWidgetUnderTest(child: OnboardingLoginPage()));

    // Rest of your test...
    await tester.tap(find.widgetWithText(ElevatedButton, 'login'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please read and accept the terms and conditions first'),
        findsOneWidget);
  });
}

Widget createWidgetUnderTest({required Widget child}) {
  return ProviderScope(
    overrides: [
      // Add any necessary provider overrides here
    ],
    child: MaterialApp(home: child),
  );
}
