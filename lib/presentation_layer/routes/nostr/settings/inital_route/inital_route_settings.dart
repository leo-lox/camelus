import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../../config/palette.dart';
import '../../../../providers/inital_route_provider.dart';

// Provider to store the selected route
final selectedRouteProvider = StateProvider<String>((ref) => '/');

class InitalRouteSettings extends ConsumerStatefulWidget {
  const InitalRouteSettings({super.key});

  @override
  InitalRouteSettingsState createState() => InitalRouteSettingsState();
}

class InitalRouteSettingsState extends ConsumerState<InitalRouteSettings> {
  // List of available routes
  final List<String> routes = [
    '/',
    '/post-and-replies',
  ];

  _laodInitialRoute() async {
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
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Initial Route Settings'),
        backgroundColor: Palette.background,
      ),
      body: ListView.builder(
        itemCount: routes.length,
        itemBuilder: (context, index) {
          final route = routes[index];
          return ListTile(
            title: Text(
              route,
              style: TextStyle(color: Palette.lightGray),
            ),
            trailing: selectedRoute == route
                ? Icon(PhosphorIcons.check(), color: Palette.white)
                : null,
            onTap: () {
              ref.read(selectedRouteProvider.notifier).state = route;
              ref.read(initalRouteProvider).saveInitialRoute(route);
            },
            tileColor: Palette.background,
          );
        },
      ),
    );
  }
}
