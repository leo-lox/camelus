import 'dart:developer';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod/riverpod.dart';

import '../../background_notification.dart';
import '../../firebase_options.dart';

Future<void> initializeFirebase(
    {bool enable = true, required ProviderContainer provider}) async {
  if (!enable) {
    return;
  }
  // Check if the current platform is supported by Firebase
  if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    // Initialize Firebase only on supported platforms
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Set up Firebase Messaging
    checkForInitialMessage();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(
      (data) => firebaseMessagingOpenedApp(data, provider),
    );

    FirebaseMessaging.onMessage
        .listen((data) => firebaseMessagingAppOpen(data, provider));
  } else {
    log('Firebase not initialized: unsupported platform');
  }
}
