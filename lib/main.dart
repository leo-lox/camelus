import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:system_theme/system_theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'domain_layer/entities/stored_account.dart';
import 'l10n/app_localizations.dart';
//import 'package:device_preview/device_preview.dart';
//import 'data_layer/db/object_box_ndk/db_object_box.dart';
import 'config/camelus_config.dart';

import 'domain_layer/usecases/app_auth.dart';
import 'lifecycle/notifications/init_firebase.dart';
import 'lifecycle/notifications/notifications_caller.dart';
import 'objectbox_isolate.dart';
import 'presentation_layer/init/init_moderation.dart';

import 'presentation_layer/providers/db_app_provider.dart';
import 'presentation_layer/providers/db_ndk_provider.dart';
import 'presentation_layer/providers/inbox_outbox_provider.dart';
import 'presentation_layer/providers/language_provider.dart';
import 'presentation_layer/providers/ndk_provider.dart';
import 'presentation_layer/providers/signer_provider.dart';
import 'presentation_layer/providers/theme_provider.dart';
import 'routes.dart';
import 'theme.dart' show getThemeVariants;

const devDeviceFrame = true;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //AppAuth.clearAllAccounts();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(
      windowOptions,
    );
  }

  final startupAccData = await AppAuth.getStartupAccountData();

  print(startupAccData.loginType);
  print(startupAccData.account?.toJson());

  // currently incompatible with recent flutter sdk https://github.com/aloisdeniel/flutter_device_preview/issues/244
  // if (kDebugMode && devDeviceFrame) {
  //   runApp(
  //     DevicePreview(
  //       enabled: kDebugMode,
  //       builder: (context) =>
  //           MyApp(initialRoute: initalData[0], pubkey: initalData[1]),
  //     ),
  //   );
  //   return;
  // }

  // Create a ProviderContainer
  final providerContainer = ProviderContainer();

  final CacheManager cacheManager = await getDbMainThread();

  providerContainer.read(dbNdkProvider.notifier).setDB(cacheManager);

  final mySigner = await AppAuth.loginWithStoredAccount(
    startupAccountData: startupAccData,
    signerNoti: providerContainer.read(signerProvider.notifier),
    ndk: providerContainer.read(ndkProvider),
  );

  // we have a signer, so we can set it
  if (mySigner != null) {
    /// get fresh nip65 data on startup
    final myPubkey = mySigner.getPublicKey();
    final inboxOutboxP = providerContainer.read(inboxOutboxProvider);
    inboxOutboxP.getNip65data(
      myPubkey,
      forceRefresh: false,
    );
  }

  final String initalRoute;

  // get inital route
  if (startupAccData.loginType == LoginType.register) {
    initalRoute = '/onboarding';
  } else {
    final appDb = providerContainer.read(dbAppProvider);
    final savedRoute = await appDb.read('initalRoute');
    initalRoute = savedRoute ?? '/home';
  }

  // check if firebase is supported on this platform
  final bool firebaseSupported = (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android ||
      kIsWeb);

  if (firebaseSupported) {
    // notifications
    await initializeFirebase(
      enable: CamelusConfig.firebaseEnabled,
      provider: providerContainer,
    );
    checkForPendingNotifications();
  }

  InitModeration.initBloomFilter(provider: providerContainer);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: initalRoute,
    routes: routes,
    redirect: (c, s) => redirects(c, s),
    debugLogDiagnostics: false,
  );

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: MyApp(
        navigatorKey: navigatorKey,
        initialRoute: initalRoute,
        pubkey: mySigner?.getPublicKey() ?? '',
        router: router,
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final String initialRoute;
  final String pubkey;
  final GlobalKey<NavigatorState> navigatorKey;
  final GoRouter router;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.pubkey,
    required this.router,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(currentLocaleProvider);

    final themeState = ref.watch(themeProvider);

    final themeVariants = getThemeVariants(
      themeType: themeState.type,
      themeColor: themeState.color,
    );

    return Portal(
      child: MaterialApp.router(
        routerConfig: router,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        debugShowCheckedModeBanner: false,
        title: 'camelus',
        locale: currentLocale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: themeVariants.lightTheme,
        darkTheme: themeVariants.darkTheme,
        themeMode: themeState.mode,
        builder: (context, child) {
          if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
            return DragToResizeArea(
              child: Stack(
                children: [
                  child!,
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SizedBox(
                      height: 32,
                      child: Row(
                        children: [
                          Expanded(
                            child: DragToMoveArea(
                              child: Container(),
                            ),
                          ),
                          SizedBox(
                            width: 154,
                            child: WindowCaption(
                              brightness: Theme.of(context).brightness,
                              backgroundColor: Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          return child!;
        },
      ),
    );
  }
}
