import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';

import '../../domain_layer/usecases/app_auth.dart';
import '../../objectbox.g.dart';
import '../../presentation_layer/providers/db_ndk_provider.dart';
import '../../presentation_layer/providers/ndk_provider.dart';
import '../../presentation_layer/providers/signer_provider.dart';
import 'process_fcm_msg.dart';

/// called when the app is in the background or terminated.
/// runs in seperate bg thread
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log("Handling a background message: ${message.messageId}");

  final providerContainer = await _setupProviderBackgroundThread();

  await processFcmData(
    data: message.data,
    provider: providerContainer,
    isBackground: true,
  );

  // close db after processing
  providerContainer.read(dbNdkProvider)!.close();
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
    providerContainer
        .read(ndkProviderLight)
        .accounts
        .loginExternalSigner(signer: mySigner);
    providerContainer.read(signerProvider.notifier).setSigner(mySigner);
  }

  return providerContainer;
}
