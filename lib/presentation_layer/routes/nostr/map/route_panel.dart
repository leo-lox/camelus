import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'route_provider.dart';
import 'route_search_field.dart';

/// The route planning panel that appears at the top of the map.
///
/// Contains origin/destination search fields, optional intermediate stops,
/// travel mode selector, and a route button.
class RoutePanel extends ConsumerWidget {
  const RoutePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final theme = Theme.of(context);

    if (!routeState.isRoutePanelOpen) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 50, 12, 0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft()),
                  onPressed: () {
                    ref.read(routeProvider.notifier).closePanel();
                  },
                  tooltip: 'Close',
                ),
                const Spacer(),
                if (routeState.waypoints.length >= 2)
                  TextButton.icon(
                    onPressed: () {
                      ref.read(routeProvider.notifier).swapOriginDestination();
                    },
                    icon: Icon(PhosphorIcons.arrowsVertical(), size: 18),
                    label: const Text('Swap'),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),

          // Waypoint search fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                for (int i = 0; i < routeState.waypoints.length; i++) ...[
                  if (i > 0 && i < routeState.waypoints.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Row(
                        children: [
                          Container(
                            width: 2,
                            height: 8,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(PhosphorIcons.x(), size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                            onPressed: () => ref
                                .read(routeProvider.notifier)
                                .removeWaypoint(i),
                            tooltip: 'Remove stop',
                          ),
                        ],
                      ),
                    ),
                  RouteSearchField(
                    waypointIndex: i,
                    hintText: i == 0
                        ? 'Choose starting point'
                        : 'Choose destination',
                    isFirst: i == 0,
                    isLast: i == routeState.waypoints.length - 1,
                  ),
                  if (i < routeState.waypoints.length - 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 28),
                      child: Container(
                        width: 2,
                        height: 4,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Add stop button
          Padding(
            padding: const EdgeInsets.only(left: 28, right: 8, bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 2,
                  height: 16,
                  color: theme.colorScheme.outlineVariant,
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    ref.read(routeProvider.notifier).addWaypoint();
                  },
                  icon: Icon(PhosphorIcons.plusCircle(), size: 18),
                  label: const Text('Add stop'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Error message
          if (routeState.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                routeState.error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
