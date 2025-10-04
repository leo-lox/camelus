import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
//import 'package:device_preview/device_preview.dart';
//import 'data_layer/db/object_box_ndk/db_object_box.dart';
import 'config/camelus_config.dart';
import 'domain_layer/entities/starter_pack_identifier.dart';
import 'lifecycle/connectivity/connectivity.dart';
import 'lifecycle/deep_links.dart';
import 'domain_layer/usecases/app_auth.dart';
import 'lifecycle/notifications/init_firebase.dart';
import 'lifecycle/notifications/notifications_caller.dart';
import 'objectbox_isolate.dart';
import 'presentation_layer/components/starter_packs/edit_starter_pack/edit_starter_pack.dart';
import 'presentation_layer/components/starter_packs/open_starter_pack.dart';
import 'presentation_layer/init/init_moderation.dart';
import 'presentation_layer/providers/app_lifecycle_provider.dart';
import 'presentation_layer/providers/db_app_provider.dart';
import 'presentation_layer/providers/db_ndk_provider.dart';
import 'presentation_layer/providers/inbox_outbox_provider.dart';
import 'presentation_layer/providers/ndk_provider.dart';
import 'presentation_layer/providers/signer_provider.dart';
import 'presentation_layer/routes/home_page.dart';
import 'presentation_layer/routes/nostr/blockedUsers/blocked_users.dart';
import 'presentation_layer/routes/nostr/event_view/event_view_page.dart';
import 'presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'presentation_layer/routes/nostr/profile/edit_profile_page.dart';
import 'presentation_layer/routes/nostr/profile/profile_page_2.dart';
import 'presentation_layer/routes/nostr/search_feed_page/search_feed_page.dart';
import 'presentation_layer/routes/nostr/settings/file_servers/settings_file_servers.dart';
import 'presentation_layer/routes/nostr/settings/inital_route/inital_route_settings.dart';
import 'presentation_layer/routes/nostr/settings/locale/locale_settings.dart';
import 'presentation_layer/routes/nostr/settings/moderation/moderation_settings.dart';
import 'presentation_layer/routes/nostr/settings/settings_page.dart';
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
    WindowOptions windowOptions = WindowOptions(
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions);
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
    initalRoute = savedRoute ?? '/';
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

class MyApp extends ConsumerWidget {
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
  Widget build(BuildContext context, ref) {
    return Portal(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        debugShowCheckedModeBanner: false,
        title: 'camelus',
        theme: theme.themeMap["DARK"],
        initialRoute: initialRoute,
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
            case '/posts-and-replies':
              return CupertinoPageRoute(builder: (context) {
                return HomePage(
                  pubkey: pubkey,
                  initialTab: settings.name,
                );
              });

            case '/search':
              return CupertinoPageRoute(builder: (context) {
                return HomePage(
                  pubkey: pubkey,
                  initialPage: 1,
                );
              });

            case '/notifications':
              return CupertinoPageRoute(builder: (context) {
                return HomePage(
                  pubkey: pubkey,
                  initialPage: 2,
                );
              });

            case '/onboarding':
              return MaterialPageRoute(
                builder: (context) => const NostrOnboarding(),
              );

            case '/settings':
              return MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              );
            case '/settings/file-servers':
              return MaterialPageRoute(
                builder: (context) => const SettingsFileServers(),
              );
            case '/settings/inital-route':
              return MaterialPageRoute(
                builder: (context) => const InitalRouteSettings(),
              );
            case '/settings/locale':
              return MaterialPageRoute(
                builder: (context) => const LocaleSettingsPage(),
              );
            case '/settings/moderation':
              return MaterialPageRoute(
                builder: (context) => const ModerationSettingsPage(),
              );
            case '/nostr/event':
              return CupertinoPageRoute(
                builder: (context) => EventViewPage(
                    rootNoteId: (settings.arguments
                        as Map<String, dynamic>)['root'] as String,
                    openNoteId: (settings.arguments
                        as Map<String, dynamic>)['scrollIntoView'] as String?),
              );

            case '/nostr/profile':
              return MaterialPageRoute(
                builder: (context) =>
                    ProfilePage2(pubkey: settings.arguments as String),
              );
            case '/nostr/profile/edit':
              return MaterialPageRoute(
                builder: (context) =>
                    EditProfilePage(pubkey: settings.arguments as String),
              );
            case '/nostr/search':
              return PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SearchFeedPage(query: settings.arguments as String),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              );
            case '/nostr/blockedUsers':
              return MaterialPageRoute(
                builder: (context) => const BlockedUsers(),
              );
            case '/edit-starter-pack':
              return MaterialPageRoute(
                builder: (context) => EditStarterPack(
                  starterPackIdentifier:
                      settings.arguments as StarterPackIdentifier,
                ),
              );
            case '/open-starter-pack':
              return MaterialPageRoute(
                builder: (context) => OpenStarterPack(
                  starterPackIdentifier:
                      settings.arguments as StarterPackIdentifier,
                ),
              );
          }
          assert(false, 'Need to implement ${settings.name}');
          return null;
        },
      ),
    );
  }
}
