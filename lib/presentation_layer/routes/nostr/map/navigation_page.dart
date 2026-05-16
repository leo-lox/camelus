import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'live_location_provider.dart';
import 'navigation_provider.dart';
import 'valhalla_routing_service.dart';

/// Full-screen turn-by-turn navigation page.
///
/// Google Maps-style UI:
/// - Full-screen map with route polyline (blue) + upcoming segment (green)
/// - Top: current turn instruction card with icon, street name, distance
/// - Bottom: ETA bar with remaining time/distance, speed indicator, close button
/// - Live GPS tracking with compass heading and speed-based camera pitch
/// - Preview mode toggle for manual maneuver stepping
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
  CircleAnnotationManager? _userPuckManager;
  PolylineAnnotationManager? _headingIndicatorManager;

  // Annotation instances for smooth puck updates (no delete+create flicker)
  CircleAnnotation? _puckAnnotation;
  final List<PolylineAnnotation?> _headingAnnotations = [];

  // Camera state
  DateTime _lastCameraUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  static const _cameraThrottleMs = 400;

  /// True when the camera is following the user. Set to false when the user
  /// manually pans/zooms the map; reset to true when they tap the recenter button.
  bool _isFollowingUser = true;

  /// True when the map bearing follows the user's heading. When false, north
  /// is always up. Toggled via the orientation button.
  bool _isHeadingUp = true;

  @override
  void initState() {
    super.initState();
    // Start navigation + location services immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationProvider.notifier)
          .startNavigation(
            routeResponse: widget.routeResponse,
            routePoints: widget.routePoints,
          );
      // Request permission and start GPS tracking
      ref.read(liveLocationProvider.notifier).requestPermissionAndStart();
    });
  }

  // Stored subscriptions so we can cancel them before dispose
  ProviderSubscription<UserLocation?>? _locationSubscription;
  ProviderSubscription<NavigationState?>? _navSubscription;

  @override
  void dispose() {
    // Cancel subscriptions BEFORE super.dispose to prevent ref usage
    // after the widget is unmounted
    _locationSubscription?.close();
    _navSubscription?.close();
    _routeLineManager?.deleteAll();
    _upcomingLineManager?.deleteAll();
    _waypointManager?.deleteAll();
    _userPuckManager?.deleteAll();
    _headingIndicatorManager?.deleteAll();
    // Clear navigation state when leaving
    ref.read(navigationProvider.notifier).stopNavigation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navState = ref.watch(navigationProvider);
    final locPermission = ref
        .watch(liveLocationProvider.notifier)
        .permissionStatus;
    final userLoc = ref.watch(liveLocationProvider);

    if (navState == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen map
          MapWidget(onMapCreated: _onMapCreated),

          // Location permission banner (shown over everything)
          if (locPermission == LocationPermissionStatus.denied ||
              locPermission == LocationPermissionStatus.permanentlyDenied)
            _PermissionBanner(
              isPermanentlyDenied:
                  locPermission == LocationPermissionStatus.permanentlyDenied,
            ),

          // Top: instruction card
          _InstructionCard(navState: navState),

          // Bottom: ETA bar
          _EtaBar(navState: navState),

          // Navigation controls FAB cluster (bottom-right, above ETA bar)
          if (userLoc != null)
            Positioned(
              right: 16,
              bottom: 90,
              child: SafeArea(
                top: false,
                child: _NavigationControls(
                  navState: navState,
                  isFollowingUser: _isFollowingUser,
                  isHeadingUp: _isHeadingUp,
                  onRecenter: () {
                    setState(() => _isFollowingUser = true);
                    // Immediately fly to user location
                    final loc = ref.read(liveLocationProvider);
                    if (loc != null) {
                      final updatedNavState = ref.read(navigationProvider);
                      if (updatedNavState != null) {
                        _updateLiveCamera(updatedNavState, loc);
                      }
                    }
                  },
                  onToggleOrientation: () {
                    setState(() => _isHeadingUp = !_isHeadingUp);
                  },
                  onTogglePreview: () {
                    ref.read(navigationProvider.notifier).togglePreviewMode();
                    // Switching to preview also re-enables following
                    setState(() => _isFollowingUser = true);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    await _drawRoute();
    await _setupMapStyle();

    // Create annotation managers for user puck + heading indicator
    _userPuckManager ??= await _mapboxMap.annotations
        .createCircleAnnotationManager(id: 'nav-user-puck');
    _headingIndicatorManager ??= await _mapboxMap.annotations
        .createPolylineAnnotationManager(id: 'nav-heading-indicator');

    // Pre-create puck + heading annotations so we can update them in-place
    // (avoids deleteAll+create flicker on every GPS tick)
    await _ensurePuckAnnotations();

    // Detect user gestures: pause camera following when the user pans/zooms
    _mapboxMap.setOnMapMoveListener((context) {
      if (_isFollowingUser) {
        setState(() => _isFollowingUser = false);
      }
    });
    _mapboxMap.setOnMapZoomListener((context) {
      if (_isFollowingUser) {
        setState(() => _isFollowingUser = false);
      }
    });

    // Listen for live location updates (GPS + compass fused)
    _locationSubscription = ref.listenManual<UserLocation?>(
      liveLocationProvider,
      (prev, next) {
        if (!mounted) return;
        if (next != null) {
          _updateUserPuck(next);
          // Feed location to navigation provider for auto-advance
          final navState = ref.read(navigationProvider);
          if (navState != null && !navState.isPreviewMode) {
            ref.read(navigationProvider.notifier).updateUserLocation(next);
          }
          // Update camera in live mode (only if following user)
          final updatedNavState = ref.read(navigationProvider);
          if (updatedNavState != null &&
              !updatedNavState.isPreviewMode &&
              _isFollowingUser) {
            _updateLiveCamera(updatedNavState, next);
          }
        }
      },
    );

    // Listen for navigation state changes to update the upcoming segment
    _navSubscription = ref.listenManual<NavigationState?>(navigationProvider, (
      prev,
      next,
    ) {
      if (!mounted) return;
      if (next != null) {
        if (prev == null ||
            next.currentManeuverIndex != prev.currentManeuverIndex) {
          _updateUpcomingSegment(next);
        }
        // In preview mode, position camera at the maneuver
        if (next.isPreviewMode &&
            (prev == null ||
                next.currentManeuverIndex != prev.currentManeuverIndex)) {
          _updatePreviewCamera(next);
        }
      }
    });

    // Initial camera positioning
    _updatePreviewCamera(ref.read(navigationProvider));
  }

  Future<void> _setupMapStyle() async {
    try {
      await _mapboxMap.style.setStyleTerrain(
        '{"source": "mapbox-dem", "exaggeration": 1.5}',
      );
      await _mapboxMap.style.addSource(
        RasterDemSource(
          id: 'mapbox-dem',
          url: 'mapbox://mapbox.mapbox-terrain-dem-v1',
          tileSize: 514,
          maxzoom: 14,
        ),
      );
      await _mapboxMap.style.addLayer(
        SkyLayer(
          id: 'sky-layer',
          skyType: SkyType.ATMOSPHERE,
          skyAtmosphereSun: [0.0, 0.0],
          skyAtmosphereSunIntensity: 15.0,
        ),
      );
    } catch (_) {
      // Terrain/sky setup is optional; navigation still works without it
    }
  }

  /// Pre-create puck and heading annotations so they can be updated
  /// in-place (avoids flicker from delete+create on every GPS tick).
  Future<void> _ensurePuckAnnotations() async {
    if (_userPuckManager == null || _headingIndicatorManager == null) return;

    if (_puckAnnotation == null) {
      _puckAnnotation = await _userPuckManager!.create(
        CircleAnnotationOptions(
          geometry: Point(coordinates: Position(0, 0)),
          circleRadius: 10.0,
          circleColor: const Color(0xFF2196F3).value,
          circleStrokeColor: Colors.white.value,
          circleStrokeWidth: 4.0,
        ),
      );
    }

    // 3 polylines: shaft + left arm + right arm
    if (_headingAnnotations.length < 3) {
      _headingAnnotations.clear();
      final created = await _headingIndicatorManager!.createMulti([
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [Position(0, 0), Position(0, 0)]),
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 5.0,
          lineOpacity: 0.9,
        ),
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [Position(0, 0), Position(0, 0)]),
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
        PolylineAnnotationOptions(
          geometry: LineString(coordinates: [Position(0, 0), Position(0, 0)]),
          lineColor: const Color(0xFF2196F3).value,
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      ]);
      _headingAnnotations.addAll(created);
    }
  }

  /// Update the user's position puck on the map (smooth, no flicker).
  Future<void> _updateUserPuck(UserLocation loc) async {
    if (_userPuckManager == null || _headingIndicatorManager == null) return;
    if (_puckAnnotation == null || _headingAnnotations.length < 3) return;

    final userPoint = Point(coordinates: Position(loc.longitude, loc.latitude));

    // Update puck position in-place
    _puckAnnotation!.geometry = userPoint;
    await _userPuckManager!.update(_puckAnnotation!);

    // Compute heading arrow geometry
    final headingRad = loc.heading * math.pi / 180;
    const arrowLengthMeters = 25.0;
    const metersPerDegree = 111320.0;
    final tailLatDelta = arrowLengthMeters / metersPerDegree;
    final tailLngDelta =
        arrowLengthMeters /
        (metersPerDegree * math.cos(loc.latitude * math.pi / 180));

    final tailLat = loc.latitude - tailLatDelta * math.cos(headingRad);
    final tailLng = loc.longitude - tailLngDelta * math.sin(headingRad);

    const armLengthMeters = 8.0;
    final armLatDelta = armLengthMeters / metersPerDegree;
    final armLngDelta =
        armLengthMeters /
        (metersPerDegree * math.cos(loc.latitude * math.pi / 180));
    const armAngle = 0.4;

    final leftArmLat =
        tailLat -
        armLatDelta * math.cos(headingRad - armAngle) +
        armLatDelta * math.cos(headingRad);
    final leftArmLng =
        tailLng -
        armLngDelta * math.sin(headingRad - armAngle) +
        armLngDelta * math.sin(headingRad);
    final rightArmLat =
        tailLat -
        armLatDelta * math.cos(headingRad + armAngle) +
        armLatDelta * math.cos(headingRad);
    final rightArmLng =
        tailLng -
        armLngDelta * math.sin(headingRad + armAngle) +
        armLngDelta * math.sin(headingRad);

    // Update heading polylines in-place
    final shaftLine = LineString(
      coordinates: [
        Position(tailLng, tailLat),
        Position(loc.longitude, loc.latitude),
      ],
    );
    _headingAnnotations[0]!.geometry = shaftLine;
    await _headingIndicatorManager!.update(_headingAnnotations[0]!);

    final leftLine = LineString(
      coordinates: [
        Position(tailLng, tailLat),
        Position(leftArmLng, leftArmLat),
      ],
    );
    _headingAnnotations[1]!.geometry = leftLine;
    await _headingIndicatorManager!.update(_headingAnnotations[1]!);

    final rightLine = LineString(
      coordinates: [
        Position(tailLng, tailLat),
        Position(rightArmLng, rightArmLat),
      ],
    );
    _headingAnnotations[2]!.geometry = rightLine;
    await _headingIndicatorManager!.update(_headingAnnotations[2]!);
  }

  /// Update camera to follow user in live mode with heading-up orientation.
  Future<void> _updateLiveCamera(
    NavigationState navState,
    UserLocation loc,
  ) async {
    final now = DateTime.now();
    if (now.difference(_lastCameraUpdate).inMilliseconds < _cameraThrottleMs) {
      return;
    }
    _lastCameraUpdate = now;

    final userPoint = Point(coordinates: Position(loc.longitude, loc.latitude));

    await _mapboxMap.flyTo(
      CameraOptions(
        center: userPoint,
        zoom: navState.speedBasedZoom,
        bearing: _isHeadingUp ? loc.heading : 0.0,
        pitch: navState.speedBasedPitch,
        padding: MbxEdgeInsets(top: 280, bottom: 140, left: 32, right: 32),
      ),
      MapAnimationOptions(duration: 300, startDelay: 0),
    );
  }

  /// Update camera for preview mode — position at the current maneuver start.
  Future<void> _updatePreviewCamera(NavigationState? navState) async {
    if (navState == null || widget.routePoints.isEmpty) return;

    final maneuver = navState.currentManeuver;
    if (maneuver == null) return;

    final segmentStart = maneuver.beginShapeIndex;
    if (segmentStart < widget.routePoints.length) {
      final targetPoint = widget.routePoints[segmentStart];
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

    // Draw origin/destination markers and intermediate waypoints
    await _waypointManager!.deleteAll();

    // Origin
    await _waypointManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            points.first.coordinates.lng,
            points.first.coordinates.lat,
          ),
        ),
        circleRadius: 10.0,
        circleColor: Colors.green.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 3.0,
      ),
    );

    // Intermediate waypoints (start of each leg after the first)
    final legs = widget.routeResponse.legs;
    if (legs.length > 1) {
      int pointOffset = 0;
      for (int legIndex = 1; legIndex < legs.length; legIndex++) {
        pointOffset += ValhallaRoutingService.decodePolyline6(
          legs[legIndex - 1].shape,
        ).length;
        if (pointOffset < points.length) {
          final wpPoint = points[pointOffset];
          await _waypointManager!.create(
            CircleAnnotationOptions(
              geometry: Point(
                coordinates: Position(
                  wpPoint.coordinates.lng,
                  wpPoint.coordinates.lat,
                ),
              ),
              circleRadius: 8.0,
              circleColor: Colors.orange.value,
              circleStrokeColor: Colors.white.value,
              circleStrokeWidth: 3.0,
            ),
          );
        }
      }
    }

    // Destination
    await _waypointManager!.create(
      CircleAnnotationOptions(
        geometry: Point(
          coordinates: Position(
            points.last.coordinates.lng,
            points.last.coordinates.lat,
          ),
        ),
        circleRadius: 10.0,
        circleColor: Colors.red.value,
        circleStrokeColor: Colors.white.value,
        circleStrokeWidth: 3.0,
      ),
    );
  }

  Future<void> _updateUpcomingSegment(NavigationState navState) async {
    if (widget.routePoints.isEmpty) return;

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
  }
}

/// Location permission request banner — shown when location is not granted.
class _PermissionBanner extends ConsumerWidget {
  final bool isPermanentlyDenied;

  const _PermissionBanner({required this.isPermanentlyDenied});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.8),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(20),
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      PhosphorIcons.mapPinLine(),
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Location Access Required',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isPermanentlyDenied
                          ? 'Location permission was permanently denied. Please enable it in your device settings to use turn-by-turn navigation.'
                          : 'Turn-by-turn navigation requires access to your location. Please grant the permission to continue.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(liveLocationProvider.notifier)
                            .requestPermissionAndStart();
                      },
                      icon: Icon(PhosphorIcons.navigationArrow()),
                      label: Text(
                        isPermanentlyDenied
                            ? 'Open Settings'
                            : 'Grant Permission',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation controls cluster — recenter button + orientation toggle + preview toggle.
/// Google Maps-style vertical stack on the right side of the map.
class _NavigationControls extends StatelessWidget {
  final NavigationState navState;
  final bool isFollowingUser;
  final bool isHeadingUp;
  final VoidCallback onRecenter;
  final VoidCallback onToggleOrientation;
  final VoidCallback onTogglePreview;

  const _NavigationControls({
    required this.navState,
    required this.isFollowingUser,
    required this.isHeadingUp,
    required this.onRecenter,
    required this.onToggleOrientation,
    required this.onTogglePreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Recenter / follow button
        _NavControlButton(
          icon: isFollowingUser
              ? PhosphorIcons.navigationArrow()
              : PhosphorIcons.crosshair(),
          tooltip: isFollowingUser ? 'Following' : 'Re-center',
          isActive: isFollowingUser,
          onPressed: onRecenter,
        ),
        const SizedBox(height: 8),
        // Orientation toggle (heading-up vs north-up)
        _NavControlButton(
          icon: isHeadingUp
              ? PhosphorIcons.compass()
              : PhosphorIcons.compassRose(),
          tooltip: isHeadingUp ? 'Heading up' : 'North up',
          isActive: isHeadingUp,
          onPressed: onToggleOrientation,
        ),
        const SizedBox(height: 8),
        // Preview mode toggle
        _NavControlButton(
          icon: navState.isPreviewMode
              ? PhosphorIcons.navigationArrow()
              : PhosphorIcons.eye(),
          tooltip: navState.isPreviewMode ? 'Live mode' : 'Preview mode',
          isActive: navState.isPreviewMode,
          onPressed: onTogglePreview,
          activeColor: theme.colorScheme.tertiaryContainer,
        ),
      ],
    );
  }
}

/// Individual button in the navigation controls cluster.
class _NavControlButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;
  final Color? activeColor;

  const _NavControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.isActive = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(28),
      color: isActive
          ? (activeColor ?? theme.colorScheme.primaryContainer)
          : theme.colorScheme.surface,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      child: InkWell(
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 22,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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
                            _formatDistance(
                              navState.isPreviewMode
                                  ? maneuver.length
                                  : navState.distanceToNextManeuver / 1000.0,
                            ),
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

                // Stepper controls (only in preview mode)
                if (navState.isPreviewMode) ...[
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
    if (text.startsWith('turn')) return text;
    if (text.startsWith('continue')) return text;
    if (text.startsWith('take')) return text;
    if (text.startsWith('enter')) return text;
    return text;
  }
}

/// The bottom ETA bar — Google Maps-style pill showing remaining time,
/// distance, speed, and a close button.
class _EtaBar extends ConsumerWidget {
  final NavigationState navState;

  const _EtaBar({required this.navState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isComplete = navState.isComplete;

    // Format speed for display
    final speedKmh = navState.currentSpeed * 3.6; // m/s → km/h
    final showSpeed = !navState.isPreviewMode && navState.currentSpeed > 0.5;

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
                        Row(
                          children: [
                            Text(
                              '${_formatDistanceKm(navState.remainingDistance)} remaining',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            if (showSpeed) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${speedKmh.round()} km/h',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
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

  String _formatDistanceKm(double km) {
    if (km <= 0) return '0 m';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}
