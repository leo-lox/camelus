import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';

import 'data_layer/models/nostr_note_model.dart';
import 'domain_layer/usecases/app_auth.dart';
import 'presentation_layer/providers/db_ndk_provider.dart';
import 'presentation_layer/providers/ndk_provider.dart';
import 'presentation_layer/providers/notifications_provider.dart';
import 'presentation_layer/providers/signer_provider.dart';

// app not launched
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");

  final providerContainer = await _setupProviderBackgroundThread();

  await _processMsgData(
    data: message.data,
    provider: providerContainer,
    isBackground: true,
  );
}

// Handle notification taps when app is in background but not terminated
Future<void> firebaseMessagingOpenedApp(
  RemoteMessage message,
  ProviderContainer provider,
) async {
  log("Handling a OpenedApp message: ${message.messageId}");
  _processMsgData(data: message.data, provider: provider);
}

// app is open
Future<void> firebaseMessagingAppOpen(
  RemoteMessage message,
  ProviderContainer provider,
) async {
  log('Got a message whilst in the foreground!');

  if (message.notification != null) {
    log('Message also contained a notification: ${message.notification}');
  }

  //! debug
  _processMsgData(data: message.data, provider: provider);
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

_processMsgData({
  required Map<String, dynamic> data,
  required ProviderContainer provider,
  bool isBackground = false,
}) async {
  final Map<String, dynamic> encryptedEventJson =
      jsonDecode(data['encryptedEvent']);

  final encryptedWrapEvent = Nip01Event.fromJson(encryptedEventJson);

  final ndk = isBackground
      ? provider.read(ndkProviderNoRelays)
      : provider.read(ndkProvider);

  final unwrappedEvent =
      await ndk.giftWrap.unwrapEvent(wrappedEvent: encryptedWrapEvent);

  final notiProvider = await provider.read(notificationsProvider.future);

  notiProvider.displayLocalAvatarNotification(
    title: "kind ${unwrappedEvent.kind}, id: ${unwrappedEvent.id}",
    body: unwrappedEvent.content,
    payload: jsonEncode(unwrappedEvent.toJson()),
  );
}

Future<ProviderContainer> _setupProviderBackgroundThread() async {
  final providerContainer = ProviderContainer();

  // init ndk db
  DbObjectBox dbCacheManager = DbObjectBox();
  await dbCacheManager.dbRdy;
  final CacheManager cacheManager = dbCacheManager;

  providerContainer.read(dbNdkProvider.notifier).setDB(cacheManager);
  final mySigner = await AppAuth.getEventSigner();

  if (mySigner != null) {
    /// ndk login
    providerContainer.read(ndkProvider).accounts.loginExternalSigner(
          signer: mySigner,
        );
    providerContainer.read(signerProvider.notifier).setSigner(mySigner);
  }

  return providerContainer;
}
