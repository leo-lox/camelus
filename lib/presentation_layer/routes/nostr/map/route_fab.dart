import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'route_provider.dart';

/// Floating action button to open the route planning panel.
///
/// Hidden when the route panel is already open.
class RouteFab extends ConsumerWidget {
  const RouteFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);

    if (routeState.isRoutePanelOpen) {
      return const SizedBox.shrink();
    }

    return FloatingActionButton(
      onPressed: () {
        // Open panel without pre-filling origin (user will type or tap map)
        ref.read(routeProvider.notifier).openPanel();
      },
      child: Icon(PhosphorIcons.path()),
    );
  }
}
