import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../providers/inital_route_provider.dart';

// Provider to store the selected route
final selectedRouteProvider = NotifierProvider<SelectedRouteNotifier, String>(
  SelectedRouteNotifier.new,
);

class SelectedRouteNotifier extends Notifier<String> {
  @override
  String build() {
    return '/home';
  }

  void setRoute(String route) {
    state = route;
  }
}

class InitalRouteSettings extends ConsumerStatefulWidget {
  const InitalRouteSettings({super.key});

  @override
  InitalRouteSettingsState createState() => InitalRouteSettingsState();
}

class InitalRouteSettingsState extends ConsumerState<InitalRouteSettings> {
  Future<void> _laodInitialRoute() async {
    final loadedRoute = await ref.read(initalRouteProvider).getInitialRoute();
    ref.read(selectedRouteProvider.notifier).setRoute(loadedRoute);
  }

  @override
  void initState() {
    super.initState();

    _laodInitialRoute();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.initialRouteSettings)),
      body: ListView(
        children: [
          _RouteListTile(route: '/home', name: l10n.routeHome),
          _RouteListTile(
            route: '/posts-and-replies',
            name: l10n.routePostsAndReplies,
          ),
          _RouteListTile(route: '/search', name: l10n.routeSearch),
          _RouteListTile(
            route: '/notifications',
            name: l10n.routeNotifications,
          ),
          _RouteListTile(route: '/wallet/dashboard', name: l10n.payments),
          _RouteListTile(route: '/messages', name: l10n.messages),
        ],
      ),
    );
  }
}

class _RouteListTile extends ConsumerWidget {
  final String route;
  final String name;

  const _RouteListTile({required this.route, required this.name});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRoute = ref.watch(selectedRouteProvider);

    return ListTile(
      title: Text(
        name,
        style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface),
      ),
      trailing: selectedRoute == route
          ? Icon(
              PhosphorIcons.check,
              color: Theme.of(context).colorScheme.onSurface,
            )
          : null,
      onTap: () {
        ref.read(selectedRouteProvider.notifier).setRoute(route);
        ref.read(initalRouteProvider).saveInitialRoute(route);
      },
      tileColor: Theme.of(context).colorScheme.surface,
    );
  }
}
