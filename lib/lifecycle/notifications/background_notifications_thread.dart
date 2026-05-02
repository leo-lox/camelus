import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'package:riverpod/riverpod.dart';

import '../../config/db_paths.dart';
import '../../domain_layer/usecases/app_auth.dart';
import '../../firebase_options.dart';
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
      print('[BG_FCM] Firebase.initializeApp skipped/already initialized');
    }
  }

  try {
    final providerContainer = await _setupProviderBackgroundThread();

    await processFcmData(
      data: message.data,
      provider: providerContainer,
      isBackground: true,
    );

    // close db after processing
    final db = providerContainer.read(dbNdkProvider);
    if (db != null) {
      db.close();
    }
  } catch (e, st) {
    print('[BG_FCM] handler fatal error: $e');
    print('[BG_FCM] handler stack: $st');
    // Do not rethrow in background isolate; keep service alive for next messages.
  }
}

Future<ProviderContainer> _setupProviderBackgroundThread() async {
  final providerContainer = ProviderContainer();

  // init ndk db
  // Prefer a fresh open in the bg isolate, but fall back to attach mode.
  DbObjectBox dbCacheManager;

  final dbPath = await DbPaths.getNdkDbPath();

  try {
    dbCacheManager = DbObjectBox(attach: false, directory: dbPath);
    await dbCacheManager.dbRdy;
  } catch (eFalse) {
    print('[BG_FCM] attach=false failed: $eFalse');
    try {
      dbCacheManager = DbObjectBox(attach: true, directory: dbPath);
      await dbCacheManager.dbRdy;
    } catch (eTrue) {
      log(
        'ERROR: Could not open ObjectBox in background isolate (attach=false then attach=true): $eTrue',
      );
      print('[BG_FCM] attach=true fallback failed: $eTrue');
      rethrow;
    }
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
