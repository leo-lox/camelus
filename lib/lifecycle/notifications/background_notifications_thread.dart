import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/db_paths.dart';
import '../../domain_layer/usecases/app_auth.dart';
import '../../firebase_options.dart';
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

  // check if already initialized (can happen if main thread is still alive in background)
  // doulbe init on iOS causes issues
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Already initialized at native level — safe to continue
    }
  }

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

  final dbPath = await DbPaths.getNdkDbPath();
  final isDbOpen = Store.isOpen(dbPath);

  if (isDbOpen) {
    dbCacheManager = DbObjectBox(attach: true, directory: dbPath);
  } else {
    dbCacheManager = DbObjectBox(attach: false, directory: dbPath);
  }

  await dbCacheManager.dbRdy;
  final CacheManager cacheManager = dbCacheManager;

  providerContainer.read(dbNdkProvider.notifier).setDB(cacheManager);
  final startupAcc = await AppAuth.getStartupAccountData();
  final _ = await AppAuth.loginWithStoredAccount(
    startupAccountData: startupAcc,
    signerNoti: providerContainer.read(signerProvider.notifier),
    ndk: providerContainer.read(ndkProviderLight),
  );

  return providerContainer;
}
