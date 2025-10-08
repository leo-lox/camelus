import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
import 'l10n/app_localizations.dart';
//import 'package:device_preview/device_preview.dart';
//import 'data_layer/db/object_box_ndk/db_object_box.dart';
import 'config/camelus_config.dart';

import 'lifecycle/connectivity/connectivity.dart';
import 'lifecycle/deep_links.dart';
import 'domain_layer/usecases/app_auth.dart';
import 'lifecycle/notifications/init_firebase.dart';
import 'lifecycle/notifications/notifications_caller.dart';
import 'objectbox_isolate.dart';
import 'presentation_layer/init/init_moderation.dart';
import 'presentation_layer/providers/app_lifecycle_provider.dart';
import 'presentation_layer/providers/db_app_provider.dart';
import 'presentation_layer/providers/db_ndk_provider.dart';
import 'presentation_layer/providers/inbox_outbox_provider.dart';
import 'presentation_layer/providers/language_provider.dart';
import 'presentation_layer/providers/ndk_provider.dart';
import 'presentation_layer/providers/signer_provider.dart';
import 'presentation_layer/providers/theme_provider.dart';
import 'routes.dart';
import 'theme.dart' as theme;

const devDeviceFrame = true;

/// first is route, second is pubkey
Future<List<dynamic>> _getInitialData() async {
  final mySigner = await AppAuth.getEventSigner();

  if (mySigner == null) {
    final initialRoute = '/onboarding';

    return [initialRoute, null];
  }

  return [null, mySigner];
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(
      windowOptions,
    );
  }

  final initalData = await _getInitialData();

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

  final mySigner = initalData[1] as EventSigner?;

  // Create a ProviderContainer
  final providerContainer = ProviderContainer();

  final CacheManager cacheManager = await getDbMainThread();

  providerContainer.read(dbNdkProvider.notifier).setDB(cacheManager);

  // we have a signer, so we can set it
  if (mySigner != null) {
    /// ndk login
    providerContainer.read(ndkProvider).accounts.loginExternalSigner(
          signer: mySigner,
        );
    providerContainer.read(signerProvider.notifier).setSigner(mySigner);

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
  if (initalData[0] != null) {
    initalRoute = initalData[0];
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

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: MyApp(
        navigatorKey: navigatorKey,
        initialRoute: initalRoute,
        pubkey: mySigner?.getPublicKey() ?? '',
      ),
    ),
  );

  listenDeeplinks(
    providerContainer: providerContainer,
  );

  listenToConnectivityChanges(providerContainer);

  // init lifecycle
  providerContainer.read(appLifecycleProvider);
}

class MyApp extends ConsumerStatefulWidget {
  final String initialRoute;
  final String pubkey;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.pubkey,
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      navigatorKey: widget.navigatorKey,
      initialLocation: widget.initialRoute,
      routes: routes,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(currentLocaleProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return Portal(
      child: MaterialApp.router(
        routerConfig: _router,
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
        theme: theme.buildLightTheme(themeColor),
        darkTheme: theme.buildDarkTheme(themeColor),
        themeMode: themeMode,
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
