import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';

// app not launched
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");
}

// Handle notification taps when app is in background but not terminated
Future<void> firebaseMessagingOpenedApp(RemoteMessage message) async {
  log("Handling a OpenedApp message: ${message.messageId}");
}

// app is open
Future<void> firebaseMessagingAppOpen(RemoteMessage message) async {
  log('Got a message whilst in the foreground!');
  log('Message data: ${message.data}');

  if (message.notification != null) {
    log('Message also contained a notification: ${message.notification}');
  }
}

Future<void> checkForInitialMessage() async {
  // Get any messages which caused the application to open from a terminated state
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // Handle the initial message
    log('Application opened from terminated state with message: ${initialMessage.data}');
  }
}
