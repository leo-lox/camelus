import 'dart:convert';
import 'dart:developer';
import 'dart:ui';
import 'package:camelus/presentation_layer/providers/event_signer_provider.dart';
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
import 'package:ndk/ndk.dart';

import 'domain_layer/entities/key_pair.dart';
import 'presentation_layer/routes/home_page.dart';
import 'theme.dart' as theme;

const devDeviceFrame = true;

/// returns the pubkey if keys could be loaded from storage, otherwise returns null
Future<KeyPair?> _setupKeys() async {
  FlutterSecureStorage storage = const FlutterSecureStorage();
  var nostrKeysString = await storage.read(key: "nostrKeys");
  if (nostrKeysString == null) {
    return null;
  }
  final myKeyPair = KeyPair.fromJson(json.decode(nostrKeysString));
  return myKeyPair;
}

/// first is route, second is pubkey
Future<List<dynamic>> _getInitialData() async {
  final myKeyPair = await _setupKeys();

  if (myKeyPair == null) {
    var initialRoute = '/onboarding';

    return [initialRoute, null];
  }

  return ['/', myKeyPair];
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

  final myKeyPair = initalData[1] as KeyPair?;

  // Create a ProviderContainer
  final providerContainer = ProviderContainer();

  // If we have a valid KeyPair, create and set the EventSigner
  if (myKeyPair != null) {
    final signer = Bip340EventSigner(
      privateKey: myKeyPair.privateKey,
      publicKey: myKeyPair.publicKey,
    );
    providerContainer.read(eventSignerProvider.notifier).setSigner(signer);
  }

  runApp(
    UncontrolledProviderScope(
      container: providerContainer,
      child: MyApp(
        initialRoute: initalData[0],
        pubkey: myKeyPair?.publicKey ?? '',
        myKeyPair: myKeyPair,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  final String pubkey;
  final KeyPair? myKeyPair;

  const MyApp({
    super.key,
    required this.initialRoute,
    required this.pubkey,
    required this.myKeyPair,
  });

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Portal(
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
                    rootId: (settings.arguments as Map<String, dynamic>)['root']
                        as String,
                    scrollIntoView: (settings.arguments
                        as Map<String, dynamic>)['scrollIntoView'] as String?),
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
    );
  }
}
