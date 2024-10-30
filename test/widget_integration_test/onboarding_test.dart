import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding_login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('NostrOnboarding widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: NostrOnboarding()));

    // Check if the "camelus" title appears
    expect(find.text('camelus'), findsOneWidget);

    // Check if the "paste" button appears
    expect(find.widgetWithText(ElevatedButton, 'join the conversation'),
        findsOneWidget);

    // Check if the "next" button appears
    expect(find.widgetWithText(ElevatedButton, 'login'), findsOneWidget);
  });

  testWidgets('terms not accepted', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: OnboardingLoginPage()));

    // Find the 'next' button and tap it
    await tester.tap(find.widgetWithText(ElevatedButton, 'login'));
    await tester.pump(); // Rebuild the widget after the button tap

    // Check if the Snackbar is displayed with correct message
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please read and accept the terms and conditions first'),
        findsOneWidget);
  });
}
