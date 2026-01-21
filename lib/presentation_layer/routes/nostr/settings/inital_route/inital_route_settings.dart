import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../providers/inital_route_provider.dart';

// Provider to store the selected route
final selectedRouteProvider = StateProvider<String>((ref) => '/home');

class InitalRouteSettings extends ConsumerStatefulWidget {
  const InitalRouteSettings({super.key});

  @override
  InitalRouteSettingsState createState() => InitalRouteSettingsState();
}

class InitalRouteSettingsState extends ConsumerState<InitalRouteSettings> {
  // List of available routes
  final List<String> routes = [
    '/home',
    '/posts-and-replies',
    '/search',
    '/notifications',
  ];

  // Get localized route label
  String _getRouteLabel(BuildContext context, String route) {
    switch (route) {
      case '/':
        return AppLocalizations.of(context)!.routeHome;
      case '/posts-and-replies':
        return AppLocalizations.of(context)!.routePostsAndReplies;
      case '/search':
        return AppLocalizations.of(context)!.routeSearch;
      case '/notifications':
        return AppLocalizations.of(context)!.routeNotifications;
      default:
        return route;
    }
  }

  Future<void> _laodInitialRoute() async {
    final loadedRoute = await ref.read(initalRouteProvider).getInitialRoute();
    ref.read(selectedRouteProvider.notifier).state = loadedRoute;
  }

  @override
  void initState() {
    super.initState();

    _laodInitialRoute();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = ref.watch(selectedRouteProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.initialRouteSettings),
      ),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return ListTile(
            title: Text(
              _getRouteLabel(context, route),
              style: TextStyle(
                color: Theme.of(context).colorScheme.inverseSurface,
              ),
            ),
            trailing: selectedRoute == route
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.onSurface,
                  )
                : null,
            onTap: () {
              ref.read(selectedRouteProvider.notifier).state = route;
              ref.read(initalRouteProvider).saveInitialRoute(route);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }
}
