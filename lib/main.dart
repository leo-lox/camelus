import 'dart:ui';

import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/routes/nostr/blockedUsers/blocked_users.dart';
import 'package:camelus/routes/nostr/hashtag_view/hashtag_view_page.dart';
import 'package:camelus/routes/nostr/settings/settings_page.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camelus/routes/nostr/event_view/event_view_page.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';

import 'package:flutter_mentions/flutter_mentions.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'routes/home_page.dart';
import 'theme.dart' as theme;

const devDeviceFrame = true;

//! first is route, second is pubkey
Future<List<String>> _getInitialData() async {
  var wrapper = await ProviderContainer().read(keyPairProvider.future);

  if (wrapper.keyPair == null) {
    var initialRoute = '/onboarding';
    return [initialRoute, ""];
  }

  return ['/', wrapper.keyPair!.publicKey];
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var initalData = await _getInitialData();

  if (kDebugMode && devDeviceFrame) {
    runApp(
      DevicePreview(
        enabled: kDebugMode,
        builder: (context) =>
            MyApp(initialRoute: initalData[0], pubkey: initalData[1]),
      ),
    );
    return;
  }

  runApp(MyApp(initialRoute: initalData[0], pubkey: initalData[1]));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String pubkey;
  const MyApp({Key? key, required this.initialRoute, required this.pubkey})
      : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Portal(
      child: ProviderScope(
        child: MaterialApp(
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
                      rootId: (settings.arguments
                          as Map<String, dynamic>)['root'] as String,
                      scrollIntoView: (settings.arguments
                              as Map<String, dynamic>)['scrollIntoView']
                          as String?),
                );

              case '/nostr/profile':
                return MaterialPageRoute(
                  builder: (context) =>
                      ProfilePage(pubkey: settings.arguments as String),
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
      ),
    );
  }
}
