import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data_layer/models/nostr_note_model.dart';
import 'presentation_layer/providers/notifications_provider.dart';

// app not launched
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");

  await _processMsgData(message.data);
}

// Handle notification taps when app is in background but not terminated
Future<void> firebaseMessagingOpenedApp(RemoteMessage message) async {
  log("Handling a OpenedApp message: ${message.messageId}");
  _processMsgData(message.data);
}

// app is open
Future<void> firebaseMessagingAppOpen(RemoteMessage message) async {
  log('Got a message whilst in the foreground!');

  if (message.notification != null) {
    log('Message also contained a notification: ${message.notification}');
  }

  //! debug
  _processMsgData(message.data);
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

_processMsgData(Map<String, dynamic> data) async {
  final providerContainer = ProviderContainer();

  final Map<String, dynamic> encryptedEventJson =
      jsonDecode(data['encryptedEvent']);

  final encryptedEvent = NostrNoteModel.fromJson(encryptedEventJson);

  final notiProvider =
      await providerContainer.read(notificationsProvider.future);

  notiProvider.displayLocalNotification(
    title: "kind ${encryptedEvent.kind}, id: ${encryptedEvent.id}",
    body: encryptedEvent.content,
  );
}
