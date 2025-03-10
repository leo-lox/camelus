import 'dart:io';
import 'dart:ui';

import 'package:camelus/presentation_layer/providers/db_ndk_provider.dart';
import 'package:camelus/presentation_layer/providers/inbox_outbox_provider.dart';
import 'package:camelus/presentation_layer/providers/language_provider.dart';
import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:camelus/presentation_layer/routes/nostr/search_feed_page/search_feed_page.dart';
import 'package:camelus/presentation_layer/routes/nostr/settings/locale/locale_settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
//import 'package:device_preview/device_preview.dart';
//import 'data_layer/db/object_box_ndk/db_object_box.dart';
import 'package:ndk_objectbox/ndk_objectbox.dart';
import 'deep_links.dart';
import 'domain_layer/usecases/app_auth.dart';
import 'presentation_layer/providers/db_app_provider.dart';
import 'presentation_layer/routes/home_page.dart';
import 'presentation_layer/routes/nostr/blockedUsers/blocked_users.dart';
import 'presentation_layer/routes/nostr/event_view/event_view_page.dart';
import 'presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'presentation_layer/routes/nostr/profile/profile_page_2.dart';
import 'presentation_layer/routes/nostr/settings/file_servers/settings_file_servers.dart';
import 'presentation_layer/routes/nostr/settings/inital_route/inital_route_settings.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  // init ndk db
  DbObjectBox dbCacheManager = DbObjectBox();
  await dbCacheManager.dbRdy;
  final CacheManager cacheManager = dbCacheManager;

  providerContainer.read(dbNdkProvider.notifier).setDB(cacheManager);

  // we have a signer, so we can set it
  if (mySigner != null) {
    /// ndk login
    providerContainer.read(ndkProvider).accounts.loginExternalSigner(
          signer: mySigner,
        );

    /// get fresh nip65 data on startup
    final myPubkey = mySigner.getPublicKey();
    final inboxOutboxP = providerContainer.read(inboxOutboxProvider);
    inboxOutboxP.getNip65data(
      myPubkey,
      forceRefresh: true,
    );
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final String initalRoute;

  // get inital route
  if (initalData[0] != null) {
    initalRoute = initalData[0];
  } else {
    final appDb = providerContainer.read(dbAppProvider);

    final savedRoute = await appDb.read('initalRoute');
    initalRoute = savedRoute ?? '/';
  }

  listenDeeplinks(
    navigatorKey: navigatorKey,
    providerContainer: providerContainer,
  );

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
    // set system locale if no locale is set
    ref
        .read(languageProvider.notifier)
        .initializeWithSystemLocaleIfNeeded(context);
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
            case '/post-and-replies':
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
          }
          assert(false, 'Need to implement ${settings.name}');
          return null;
        },
      ),
    );
  }
}
