import 'package:camelus/routes/nostr/onboarding/onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('NostrOnboarding widget test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: NostrOnboarding()));

    // Check if the "camelus" title appears
    expect(find.text('camelus'), findsOneWidget);

    // Check if the "early preview" subtitle appears
    expect(find.text('early preview'), findsOneWidget);

    // Check if the "This is your private key:" label appears
    expect(find.text('This is your private key:'), findsOneWidget);

    // Check if the "paste" button appears
    expect(find.widgetWithText(ElevatedButton, 'paste'), findsOneWidget);

    // Check if the "next" button appears
    expect(find.widgetWithText(ElevatedButton, 'next'), findsOneWidget);

    // Check if the "I have read and accept the " label appears
    expect(find.text('I have read and accept the '), findsOneWidget);

    // Check if the "terms and conditions" link appears
    expect(find.text('terms and conditions'), findsOneWidget);

    // Check if the "privacy policy" link appears
    expect(find.text('privacy policy'), findsOneWidget);
  });

  testWidgets('terms not accepted', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: NostrOnboarding()));

    // Find the 'next' button and tap it
    await tester.tap(find.widgetWithText(ElevatedButton, 'next'));
    await tester.pump(); // Rebuild the widget after the button tap

    // Check if the Snackbar is displayed with correct message
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Please read and accept the terms and conditions first'),
        findsOneWidget);
  });
}
