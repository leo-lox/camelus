import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/usecases/notifications.dart';

import 'process_fcm_msg.dart';

/// checks if launched through a notification
Future<void> checkForPendingNotifications() async {
  try {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();
    // Check if app was launched from a notification
    final NotificationAppLaunchDetails? launchDetails =
        await notificationsPlugin.getNotificationAppLaunchDetails();

    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      // App was launched from a notification
      final payload = launchDetails.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        Notifications.processNotificationPayload(payload);
      }
    }
  } catch (e) {
    log('Error checking pending notifications: $e');
  }
}

// called when a user presses a notification message displayed via FCM.
// and if the app has opened from a background state (not terminated).
Future<void> firebaseMessagingOpenedApp(
  RemoteMessage message,
  ProviderContainer? provider,
) async {
  log("Handling a OpenedApp message: ${message.messageId}");
}

// called when an incoming FCM payload is received whilst the Flutter instance is in the foreground.
Future<void> firebaseMessagingAppOpen(
  RemoteMessage message,
  ProviderContainer? provider,
) async {
  log('Got a message whilst in the foreground!');

  if (message.notification != null) {
    log('Message also contained a notification: ${message.notification}');
  }

  await processFcmData(data: message.data, provider: provider!);
}

/// if the application has been opened from a terminated state via a [RemoteMessage] (containing a [Notification])
/// (FCM msg with notification, not data only)
Future<void> checkForInitialMessage() async {
  // Get any messages which caused the application to open from a terminated state
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // Handle the initial message
    log('Application opened from terminated state with message: ${initialMessage.data}');
  }
}
