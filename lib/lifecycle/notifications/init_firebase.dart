import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

import '../../presentation_layer/providers/db_app_provider.dart';
import '../../presentation_layer/providers/notifications_provider.dart';
import 'notifications_caller.dart';
import '../../firebase_options.dart';
import 'background_notifications_handler.dart';

Future<void> initializeFirebase({
  bool enable = true,
  required ProviderContainer provider,
}) async {
  if (!enable) {
    return;
  }
  // Check if the current platform is supported by Firebase
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    // Initialize Firebase only on supported platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up Firebase Messaging
    checkForInitialMessage();

    if (firebaseBackgroundHandler != null) {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler!);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(
      (data) => firebaseMessagingOpenedApp(data, provider),
    );

    FirebaseMessaging.onMessage.listen(
      (data) => firebaseMessagingAppOpen(data, provider),
    );

    /// listen to token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final notiProvider = await provider.read(notificationsProvider.future);
      final appDb = provider.read(dbAppProvider);
      await appDb.save(key: "fcm_token", value: newToken);
      await notiProvider.registerDevice(token: newToken);
    });
  } else {
    log('Firebase not initialized: unsupported platform');
  }
}
