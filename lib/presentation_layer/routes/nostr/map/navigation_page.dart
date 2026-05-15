import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'navigation_provider.dart';
import 'valhalla_routing_service.dart';

/// Full-screen turn-by-turn navigation page.
///
/// Google Maps-style UI:
/// - Full-screen map with route polyline (blue) + upcoming segment (green)
/// - Top: current turn instruction card with icon, street name, distance
/// - Bottom: ETA bar with remaining time/distance, speed indicator, close button
/// - Advance/retreat controls for maneuver stepping
class NavigationPage extends ConsumerStatefulWidget {
  final ValhallaRouteResponse routeResponse;
  final List<Point> routePoints;

  const NavigationPage({
    super.key,
    required this.routeResponse,
    required this.routePoints,
  });

  @override
  ConsumerState<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<NavigationPage> {
  late MapboxMap _mapboxMap;
  PolylineAnnotationManager? _routeLineManager;
  PolylineAnnotationManager? _upcomingLineManager;
  CircleAnnotationManager? _waypointManager;

  @override
  void initState() {
    super.initState();
    // Start navigation immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationProvider.notifier)
          .startNavigation(
            routeResponse: widget.routeResponse,
            routePoints: widget.routePoints,
          );
    });
  }

  @override
  void dispose() {
    _routeLineManager?.deleteAll();
    _upcomingLineManager?.deleteAll();
    _waypointManager?.deleteAll();
    // Clear navigation state when leaving
    ref.read(navigationProvider.notifier).stopNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);

    if (navState == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          MapWidget(
            // viewport: CameraViewportState(
            //   center: Point(coordinates: Position(4.891791, 52.355290)),
            //   zoom: 16.0,
            //   bearing: 0.0,
            //   pitch: 45.0,
            // ),
            onMapCreated: _onMapCreated,
          ),

          // Top: instruction card
          _InstructionCard(navState: navState),

          // Bottom: ETA bar
          _EtaBar(navState: navState),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    _drawRoute();
  }

  Future<void> _drawRoute() async {
    _routeLineManager ??= await _mapboxMap.annotations
        .createPolylineAnnotationManager(id: 'nav-route-line');
    _upcomingLineManager ??= await _mapboxMap.annotations
        .createPolylineAnnotationManager(id: 'nav-upcoming-line');
    _waypointManager ??= await _mapboxMap.annotations
        .createCircleAnnotationManager(id: 'nav-waypoints');

    final points = widget.routePoints;
    if (points.isEmpty) return;

    // Draw the full route in a muted color
    await _routeLineManager!.deleteAll();
    await _routeLineManager!.create(
      PolylineAnnotationOptions(
        geometry: LineString(
          coordinates: points
              .map((p) => Position(p.coordinates.lng, p.coordinates.lat))
              .toList(),
        ),
        lineColor: const Color(0xFF90CAF9).value, // light blue
        lineWidth: 8.0,
        lineOpacity: 0.6,
        lineJoin: LineJoin.ROUND,
      ),
    );

    // Draw origin/destination markers
    await _waypointManager!.deleteAll();
    await _waypointManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            points.first.coordinates.lng,
            points.first.coordinates.lat,
          ),
        ),
        circleRadius: 8.0,
        circleColor: Colors.green.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 3.0,
      ),
    );
    await _waypointManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            points.last.coordinates.lng,
            points.last.coordinates.lat,
          ),
        ),
        circleRadius: 8.0,
        circleColor: Colors.red.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 3.0,
      ),
    );

    // Listen for navigation state changes to update the upcoming segment
    ref.listenManual<NavigationState?>(navigationProvider, (prev, next) {
      if (next != null &&
          prev != null &&
          next.currentManeuverIndex != prev.currentManeuverIndex) {
        _updateUpcomingSegment(next);
      }
    });

    // Initial camera positioning
    _updateCameraAndSegment(ref.read(navigationProvider));
  }

  Future<void> _updateUpcomingSegment(NavigationState navState) async {
    await _updateCameraAndSegment(navState);
  }

  Future<void> _updateCameraAndSegment(NavigationState? navState) async {
    if (navState == null || widget.routePoints.isEmpty) return;

    final maneuver = navState.currentManeuver;
    if (maneuver == null) return;

    final points = widget.routePoints;

    // Highlight the current maneuver segment in bright blue
    await _upcomingLineManager!.deleteAll();
    final segmentStart = maneuver.beginShapeIndex;
    final segmentEnd = maneuver.endShapeIndex.clamp(0, points.length - 1);
    if (segmentStart < segmentEnd && segmentStart < points.length) {
      final segmentPoints = points.sublist(segmentStart, segmentEnd + 1);
      await _upcomingLineManager!.create(
        PolylineAnnotationOptions(
          geometry: LineString(
            coordinates: segmentPoints
                .map((p) => Position(p.coordinates.lng, p.coordinates.lat))
                .toList(),
          ),
          lineColor: Colors.blue.value,
          lineWidth: 10.0,
          lineOpacity: 1.0,
          lineJoin: LineJoin.ROUND,
        ),
      );
    }

    // Position camera at the start of the current maneuver
    if (segmentStart < points.length) {
      final targetPoint = points[segmentStart];
      await _mapboxMap.flyTo(
        CameraOptions(
          center: targetPoint,
          zoom: 17.0,
          padding: MbxEdgeInsets(top: 280, bottom: 140, left: 32, right: 32),
        ),
        MapAnimationOptions(duration: 800, startDelay: 0),
      );
    }
  }
}

/// The top instruction card — shows the current turn direction, street name,
/// and distance to the next maneuver. Google Maps-style with rounded corners,
/// shadow, and large turn icon.
class _InstructionCard extends ConsumerWidget {
  final NavigationState navState;

  const _InstructionCard({required this.navState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final maneuver = navState.currentManeuver;
    final nextManeuver = navState.nextManeuver;

    if (maneuver == null) return const SizedBox.shrink();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: theme.colorScheme.surface,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Main instruction row
                Row(
                  children: [
                    // Large turn icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: _getManeuverIcon(maneuver.type)),
                    ),
                    const SizedBox(width: 16),
                    // Instruction text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            maneuver.instruction,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (maneuver.streetNames != null &&
                              maneuver.streetNames!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                maneuver.streetNames!.join(', '),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Distance to next maneuver
                    SizedBox(
                      width: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatDistance(maneuver.length),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          if (nextManeuver != null)
                            Text(
                              'then ${_shortInstruction(nextManeuver)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Stepper controls (since we don't have GPS, user advances manually)
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      icon: Icon(PhosphorIcons.caretLeft()),
                      onPressed: navState.currentManeuverIndex > 0
                          ? () => ref
                                .read(navigationProvider.notifier)
                                .previousManeuver()
                          : null,
                      tooltip: 'Previous step',
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Step ${navState.currentManeuverIndex + 1} of ${navState.allManeuvers.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      icon: Icon(PhosphorIcons.caretRight()),
                      onPressed: !navState.isComplete
                          ? () => ref
                                .read(navigationProvider.notifier)
                                .nextManeuver()
                          : null,
                      tooltip: 'Next step',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getManeuverIcon(int type) {
    switch (type) {
      case 0: // kNone
        return Icon(PhosphorIcons.arrowUp(), size: 32);
      case 1: // kStart
        return Icon(PhosphorIcons.flag(), size: 32, color: Colors.green);
      case 4: // kDestination
        return Icon(PhosphorIcons.mapPin(), size: 32, color: Colors.red);
      case 6: // kSlightRight
        return Icon(PhosphorIcons.arrowUpRight(), size: 32);
      case 7: // kRight
        return Icon(PhosphorIcons.arrowRight(), size: 32);
      case 8: // kSharpRight
        return Icon(PhosphorIcons.arrowDownRight(), size: 32);
      case 10: // kRightThenLeft
      case 15: // kUturn
        return Icon(PhosphorIcons.arrowUUpLeft(), size: 32);
      case 11: // kLeftThenRight
        return Icon(PhosphorIcons.arrowUUpRight(), size: 32);
      case 12: // kSlightLeft
        return Icon(PhosphorIcons.arrowUpLeft(), size: 32);
      case 13: // kLeft
        return Icon(PhosphorIcons.arrowLeft(), size: 32);
      case 14: // kSharpLeft
        return Icon(PhosphorIcons.arrowDownLeft(), size: 32);
      case 16: // kRampStraight
        return Icon(PhosphorIcons.arrowBendUpRight(), size: 32);
      case 17: // kRampRight
        return Icon(PhosphorIcons.arrowBendUpRight(), size: 32);
      case 18: // kRampLeft
        return Icon(PhosphorIcons.arrowBendUpLeft(), size: 32);
      case 26: // kRoundaboutEnter
        return Icon(PhosphorIcons.arrowsClockwise(), size: 32);
      case 27: // kRoundaboutExit
        return Icon(PhosphorIcons.arrowRight(), size: 32);
      case 30: // kTransit
        return Icon(PhosphorIcons.bus(), size: 32);
      case 35:
      case 36:
      case 37: // transit connections
        return Icon(PhosphorIcons.trainSimple(), size: 32);
      default:
        return Icon(PhosphorIcons.arrowUp(), size: 32);
    }
  }

  String _formatDistance(double km) {
    if (km <= 0) return '';
    if (km < 0.01) return 'Now';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _shortInstruction(ValhallaManeuver maneuver) {
    final text = maneuver.instruction.toLowerCase();
    // Extract just the direction verb
    if (text.startsWith('turn')) return text;
    if (text.startsWith('continue')) return text;
    if (text.startsWith('take')) return text;
    if (text.startsWith('enter')) return text;
    return text;
  }
}

/// The bottom ETA bar — Google Maps-style pill showing remaining time,
/// distance, destination label, and a close button.
class _EtaBar extends ConsumerWidget {
  final NavigationState navState;

  const _EtaBar({required this.navState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isComplete = navState.isComplete;

    return Positioned(
      left: 12,
      right: 12,
      bottom: 12,
      child: SafeArea(
        top: false,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(28),
          color: isComplete ? Colors.green : theme.colorScheme.primary,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                // Left: destination icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Icon(
                      isComplete
                          ? PhosphorIcons.flag()
                          : PhosphorIcons.navigationArrow(),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Center: ETA info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isComplete)
                        Text(
                          'You have arrived',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      else ...[
                        Text(
                          _formatDuration(navState.remainingTime),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDistance(navState.remainingDistance)} remaining',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Right: close button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      color: Colors.white,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Stop navigation',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    if (seconds < 60) return '< 1 min';
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  String _formatDistance(double km) {
    if (km <= 0) return '0 m';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}
