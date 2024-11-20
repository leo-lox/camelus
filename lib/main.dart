import 'dart:ui';

import 'package:camelus/presentation_layer/providers/inbox_outbox_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/ndk.dart';
//import 'package:device_preview/device_preview.dart';

import 'deep_links.dart';
import 'domain_layer/usecases/app_auth.dart';
import 'presentation_layer/providers/event_signer_provider.dart';
import 'presentation_layer/routes/home_page.dart';
import 'presentation_layer/routes/nostr/blockedUsers/blocked_users.dart';
import 'presentation_layer/routes/nostr/event_view/event_view_page.dart';
import 'presentation_layer/routes/nostr/hashtag_view/hashtag_view_page.dart';
import 'presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'presentation_layer/routes/nostr/profile/profile_page_2.dart';
import 'presentation_layer/routes/nostr/settings/settings_page.dart';
import 'theme.dart' as theme;

const devDeviceFrame = true;

/// first is route, second is pubkey
Future<List<dynamic>> _getInitialData() async {
  final mySigner = await AppAuth.getEventSigner();

  if (mySigner == null) {
    var initialRoute = '/onboarding';

    return [initialRoute, null];
  }

  return ['/', mySigner];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var initalData = await _getInitialData();

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

  // we have a signer, so we can set it
  if (mySigner != null) {
    providerContainer.read(eventSignerProvider.notifier).setSigner(mySigner);

    /// get fresh nip65 data on startup
    final myPubkey = mySigner.getPublicKey();
    final inboxOutboxP = providerContainer.read(inboxOutboxProvider);
    inboxOutboxP.getNip65data(
      myPubkey,
      forceRefresh: true,
    );
  }

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  listenDeeplinks(
    navigatorKey: navigatorKey,
  );

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: MyApp(
        navigatorKey: navigatorKey,
        initialRoute: initalData[0],
        pubkey: mySigner?.getPublicKey() ?? '',
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String pubkey;
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({
    super.key,
    required this.navigatorKey,
    required this.initialRoute,
    required this.pubkey,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
              return CupertinoPageRoute(builder: (context) {
                return HomePage(pubkey: pubkey);
              });

            case '/onboarding':
              return MaterialPageRoute(
                builder: (context) => const NostrOnboarding(),
              );

            case '/settings':
              return MaterialPageRoute(
                builder: (context) => const SettingsPage(),
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
            case '/nostr/hastag':
              return MaterialPageRoute(
                builder: (context) =>
                    HastagViewPage(hashtag: settings.arguments as String),
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
