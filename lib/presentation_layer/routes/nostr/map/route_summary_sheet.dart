import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'route_provider.dart';
import 'valhalla_routing_service.dart';

/// A bottom sheet showing the route summary and turn-by-turn directions.
///
/// Displays total time/distance at the top and a scrollable list of maneuvers.
class RouteSummarySheet extends ConsumerWidget {
  const RouteSummarySheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routeState = ref.watch(routeProvider);
    final theme = Theme.of(context);

    if (routeState.routeResponses.isEmpty || !routeState.isRoutePanelOpen) {
      return const SizedBox.shrink();
    }

    final response = routeState.routeResponse!;
    final summary = response.tripSummary;

    // Collect all maneuvers from all legs
    final allManeuvers = response.legs.expand((leg) => leg.maneuvers).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.25,
      minChildSize: 0.15,
      maxChildSize: 0.6,
      snap: true,
      snapSizes: const [0.15, 0.25, 0.6],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Travel mode selector
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: _TravelModeSelector(
                  currentMode: routeState.travelMode,
                  onModeChanged: (mode) {
                    ref.read(routeProvider.notifier).setTravelMode(mode);
                  },
                ),
              ),

              // Summary bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      PhosphorIcons.path(),
                      size: 20,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _formatDuration(summary.time),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDistance(summary.length),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    if (routeState.routeCount > 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onPrimaryContainer
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${routeState.routeCount} routes · tap map to select',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    // Start navigation button
                    Material(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          final response = routeState.routeResponse!;
                          final routePoints =
                              ValhallaRoutingService.decodePolyline6(
                                response.fullShape,
                              );
                          context.push(
                            '/map/navigation',
                            extra: {
                              'routeResponse': response,
                              'routePoints': routePoints,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PhosphorIcons.navigationArrow(),
                                size: 16,
                                color: theme.colorScheme.onPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Start',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    // Close route
                    IconButton(
                      icon: Icon(
                        PhosphorIcons.x(),
                        size: 20,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed: () {
                        ref.read(routeProvider.notifier).closePanel();
                      },
                    ),
                  ],
                ),
              ),

              // Scrollable maneuver list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: allManeuvers.length,
                  itemBuilder: (context, index) {
                    final maneuver = allManeuvers[index];
                    return _ManeuverTile(maneuver: maneuver);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) return '${seconds.round()}s';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes}min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }
}

class _TravelModeSelector extends StatelessWidget {
  final TravelMode currentMode;
  final ValueChanged<TravelMode> onModeChanged;

  const _TravelModeSelector({
    required this.currentMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SegmentedButton<TravelMode>(
      segments: [
        ButtonSegment(
          value: TravelMode.auto,
          icon: Icon(PhosphorIcons.car(), size: 18),
          label: Text('Car'),
        ),
        ButtonSegment(
          value: TravelMode.bicycle,
          icon: Icon(PhosphorIcons.bicycle(), size: 18),
          label: Text('Bike'),
        ),
        ButtonSegment(
          value: TravelMode.pedestrian,
          icon: Icon(PhosphorIcons.person(), size: 18),
          label: Text('Walk'),
        ),
        ButtonSegment(
          value: TravelMode.multimodal,
          icon: Icon(PhosphorIcons.bus(), size: 18),
          label: Text('Transit'),
        ),
      ],
      selected: {currentMode},
      onSelectionChanged: (selection) => onModeChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// A single maneuver instruction tile.
class _ManeuverTile extends StatelessWidget {
  final ValhallaManeuver maneuver;

  const _ManeuverTile({required this.maneuver});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _getManeuverIcon(maneuver.type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: SizedBox(width: 36, height: 36, child: Center(child: icon)),
        title: Text(maneuver.instruction, style: theme.textTheme.bodyMedium),
        subtitle: Text(
          _formatManeuverDistance(maneuver.length),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  Widget _getManeuverIcon(int type) {
    switch (type) {
      case 0: // kNone
        return Icon(PhosphorIcons.arrowUp());
      case 1: // kStart
        return Icon(PhosphorIcons.flag(), color: Colors.green);
      case 4: // kDestination
        return Icon(PhosphorIcons.mapPin(), color: Colors.red);
      case 6: // kSlightRight
        return Icon(PhosphorIcons.arrowUpRight());
      case 7: // kRight
        return Icon(PhosphorIcons.arrowRight());
      case 8: // kSharpRight
        return Icon(PhosphorIcons.arrowDownRight());
      case 12: // kSlightLeft
        return Icon(PhosphorIcons.arrowUpLeft());
      case 13: // kLeft
        return Icon(PhosphorIcons.arrowLeft());
      case 14: // kSharpLeft
        return Icon(PhosphorIcons.arrowDownLeft());
      case 10: // kRightThenLeft (uturn-ish)
      case 11: // kLeftThenRight (uturn-ish)
      case 15: // kUturn
        return Icon(PhosphorIcons.arrowUUpLeft());
      case 16: // kRampStraight
      case 17: // kRampRight
      case 18: // kRampLeft
        return Icon(PhosphorIcons.arrowBendUpRight());
      case 26: // kRoundaboutEnter
        return Icon(PhosphorIcons.arrowsClockwise());
      case 27: // kRoundaboutExit
        return Icon(PhosphorIcons.arrowRight());
      case 30: // kTransit
        return Icon(PhosphorIcons.bus());
      case 35: // kTransitConnectionStart
      case 36: // kTransitConnectionTransfer
      case 37: // kTransitConnectionDestination
        return Icon(PhosphorIcons.trainSimple());
      default:
        return Icon(PhosphorIcons.arrowUp());
    }
  }

  String _formatManeuverDistance(double km) {
    if (km <= 0) return '';
    if (km < 0.01) return 'A few meters';
    if (km < 1) return '${(km * 1000).round()}m';
    return '${km.toStringAsFixed(1)}km';
  }
}
