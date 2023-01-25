import 'package:camelus/routes/nostr/blockedUsers/blocked_users.dart';
import 'package:camelus/routes/nostr/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:camelus/routes/nostr/event_view/event_view_page.dart';
import 'package:camelus/routes/nostr/onboarding/onboarding.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';

import 'package:flutter_mentions/flutter_mentions.dart';

import 'routes/home_page.dart';
import 'theme.dart' as theme;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var initialRoute = '/';

    return Portal(
      child: MaterialApp(
        title: 'camelus',
        theme: theme.themeMap["DARK"],
        initialRoute: initialRoute,
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/':
              return MaterialPageRoute(
                builder: (context) => const HomePage(),
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
                builder: (context) =>
                    EventViewPage(eventId: settings.arguments as String),
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
    );
  }
}
