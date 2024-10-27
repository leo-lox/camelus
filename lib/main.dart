import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/presentation_layer/providers/key_pair_provider.dart';
import 'package:camelus/presentation_layer/routes/nostr/blockedUsers/blocked_users.dart';
import 'package:camelus/presentation_layer/routes/nostr/hashtag_view/hashtag_view_page.dart';
import 'package:camelus/presentation_layer/routes/nostr/settings/settings_page.dart';
//import 'package:device_preview/device_preview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camelus/presentation_layer/routes/nostr/event_view/event_view_page.dart';
import 'package:camelus/presentation_layer/routes/nostr/onboarding/onboarding.dart';
import 'package:camelus/presentation_layer/routes/nostr/profile/profile_page.dart';

import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'domain_layer/entities/key_pair.dart';
import 'presentation_layer/routes/home_page.dart';
import 'theme.dart' as theme;

const devDeviceFrame = true;

/// returns the pubkey if keys could be loaded from storage, otherwise returns null
Future<KeyPairWrapper> _setupKeys() async {
  FlutterSecureStorage storage = const FlutterSecureStorage();
  var nostrKeysString = await storage.read(key: "nostrKeys");
  KeyPairWrapper keyPairWrapper;
  if (nostrKeysString == null) {
    keyPairWrapper = KeyPairWrapper(keyPair: null);
    return keyPairWrapper;
  }

  var myKeyPair = KeyPair.fromJson(json.decode(nostrKeysString));
  keyPairWrapper = KeyPairWrapper(keyPair: myKeyPair);

  return keyPairWrapper;
}

/// first is route, second is pubkey
Future<List<dynamic>> _getInitialData() async {
  final myKeyPairWrapper = await _setupKeys();

  if (myKeyPairWrapper.keyPair == null) {
    var initialRoute = '/onboarding';
    KeyPairWrapper emptyKeyPair = KeyPairWrapper(keyPair: null);
    return [initialRoute, emptyKeyPair];
  }

  return ['/', myKeyPairWrapper];
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

  final myKeyPairWrapper = initalData[1] as KeyPairWrapper;

  runApp(
    MyApp(
      initialRoute: initalData[0],
      pubkey: myKeyPairWrapper.keyPair?.publicKey ?? '',
      myKeyPairWrapper: myKeyPairWrapper,
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String pubkey;
  final KeyPairWrapper myKeyPairWrapper;

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.pubkey,
    required this.myKeyPairWrapper,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Portal(
      child: ProviderScope(
        overrides: [
          keyPairProvider.overrideWith((_) {
            return myKeyPairWrapper;
          })
        ],
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
