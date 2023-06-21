import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/routes/nostr/blockedUsers/blocked_users.dart';
import 'package:camelus/routes/nostr/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:camelus/routes/nostr/event_view/event_view_page.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';

import 'package:flutter_mentions/flutter_mentions.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'routes/home_page.dart';
import 'theme.dart' as theme;

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
          debugShowCheckedModeBanner: false,
          title: 'camelus',
          theme: theme.themeMap["DARK"],
          initialRoute: initialRoute,
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(
                  builder: (context) =>
                      //HomePage(pubkey: snapshot.data![1]),
                      HomePage(
                          pubkey:
                              pubkey), //snapshot.data![1]), //pubkey: snapshot.data![1]
                );

              case '/onboarding':
                return MaterialPageRoute(
                  builder: (context) => NostrOnboarding(),
                );

              case '/settings':
                return MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                );
              case '/nostr/event':
                return MaterialPageRoute(
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
              case '/nostr/blockedUsers':
                return MaterialPageRoute(
                  builder: (context) => BlockedUsers(),
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
