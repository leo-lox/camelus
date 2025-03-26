import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'domain_layer/usecases/app_auth.dart';
import 'objectbox.g.dart';
import 'presentation_layer/providers/db_ndk_provider.dart';
import 'presentation_layer/providers/ndk_provider.dart';
import 'presentation_layer/providers/notifications_provider.dart';
import 'presentation_layer/providers/signer_provider.dart';

// called when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  log("Handling a background message: ${message.messageId}");

  final providerContainer = await _setupProviderBackgroundThread();

  await _processMsgData(
    data: message.data,
    provider: providerContainer,
    isBackground: true,
  );

  // close db after processing
  providerContainer.read(dbNdkProvider)!.close();
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

  //! debug
  await _processMsgData(data: message.data, provider: provider!);
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

Future<void> _processMsgData({
  required Map<String, dynamic> data,
  required ProviderContainer provider,
  bool isBackground = false,
}) async {
  final Map<String, dynamic> encryptedEventJson =
      jsonDecode(data['encryptedEvent']);

  final encryptedWrapEvent = Nip01Event.fromJson(encryptedEventJson);

  final ndk = isBackground
      ? provider.read(ndkProviderLight)
      : provider.read(ndkProvider);

  final unwrappedEvent =
      await ndk.giftWrap.unwrapEvent(wrappedEvent: encryptedWrapEvent);

  final notiProvider = await provider.read(notificationsProvider.future);

  await notiProvider.displayLocalAvatarNotification(
    title: "kind ${unwrappedEvent.kind}, id: ${unwrappedEvent.id}",
    body: unwrappedEvent.content,
    payload: jsonEncode(unwrappedEvent.toJson()),
  );
}

Future<ProviderContainer> _setupProviderBackgroundThread() async {
  final providerContainer = ProviderContainer();

  // init ndk db
  // db could already be open by main thread
  final DbObjectBox dbCacheManager;

  final docsDir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(docsDir.path, "ndk-obx-default");
  final isDbOpen = Store.isOpen(dbPath);

  if (isDbOpen) {
    dbCacheManager = DbObjectBox(attach: true);
  } else {
    dbCacheManager = DbObjectBox(attach: false);
  }

  await dbCacheManager.dbRdy;
  final CacheManager cacheManager = dbCacheManager;

  providerContainer.read(dbNdkProvider.notifier).setDB(cacheManager);
  final mySigner = await AppAuth.getEventSigner();

  if (mySigner != null) {
    /// ndk login
    providerContainer.read(ndkProviderLight).accounts.loginExternalSigner(
          signer: mySigner,
        );
    providerContainer.read(signerProvider.notifier).setSigner(mySigner);
  }

  return providerContainer;
}
