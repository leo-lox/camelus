import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'live_location_provider.dart';
import 'route_provider.dart';
import 'valhalla_routing_service.dart';

/// Off-route threshold in meters. If the user is farther than this from the
/// route line, a recalculation will be triggered.
const kOffRouteThresholdMeters = 50.0;

/// State for the active navigation session.
class NavigationState {
  final ValhallaRouteResponse routeResponse;
  final int currentManeuverIndex;
  final bool isNavigating;
  final List<Point> routePoints;
  final UserLocation? currentLocation;
  final double distanceToNextManeuver;

  /// When true, the user is in manual preview mode (stepper visible,
  /// no GPS camera tracking). When false, live GPS mode.
  final bool isPreviewMode;

  /// When true, a route recalculation is in progress.
  final bool isRecalculating;

  /// The original travel mode used for routing.
  final TravelMode travelMode;

  /// The original waypoints from route planning. Used for recalculation
  /// when the user goes off-route.
  final List<RouteWaypoint> originalWaypoints;

  const NavigationState({
    required this.routeResponse,
    required this.currentManeuverIndex,
    this.isNavigating = true,
    required this.routePoints,
    this.currentLocation,
    this.distanceToNextManeuver = 0.0,
    this.isPreviewMode = false,
    this.isRecalculating = false,
    this.travelMode = TravelMode.auto,
    this.originalWaypoints = const [],
  });

  /// All maneuvers flattened from all legs.
  List<ValhallaManeuver> get allManeuvers =>
      routeResponse.legs.expand((leg) => leg.maneuvers).toList();

  /// The current maneuver instruction.
  ValhallaManeuver? get currentManeuver {
    if (currentManeuverIndex < allManeuvers.length) {
      return allManeuvers[currentManeuverIndex];
    }
    return null;
  }

  /// The next maneuver (upcoming turn).
  ValhallaManeuver? get nextManeuver {
    final next = currentManeuverIndex + 1;
    if (next < allManeuvers.length) {
      return allManeuvers[next];
    }
    return null;
  }

  /// Remaining time in seconds from the current maneuver onward.
  double get remainingTime {
    double total = 0;
    for (int i = currentManeuverIndex; i < allManeuvers.length; i++) {
      total += allManeuvers[i].time;
    }
    return total;
  }

  /// Remaining distance in km from the current maneuver onward.
  double get remainingDistance {
    double total = 0;
    for (int i = currentManeuverIndex; i < allManeuvers.length; i++) {
      total += allManeuvers[i].length;
    }
    return total;
  }

  /// Whether navigation is complete (reached destination).
  bool get isComplete => currentManeuverIndex >= allManeuvers.length - 1;

  /// Current user speed in m/s (0 if no location).
  double get currentSpeed => currentLocation?.speed ?? 0.0;

  /// Current user heading in degrees (0 = North, clockwise).
  double get currentHeading => currentLocation?.heading ?? 0.0;

  /// Camera pitch based on speed.
  /// - Stopped (<= 0 m/s): 0° (top-down 2D)
  /// - Walking (0–5 m/s): 30°
  /// - Driving slow (5–15 m/s): 50°
  /// - Highway (> 15 m/s): 60°
  double get speedBasedPitch {
    final speed = currentSpeed;
    if (speed <= 0) return 0.0;
    if (speed < 5) return 30.0;
    if (speed < 15) return 50.0;
    return 60.0;
  }

  /// Camera zoom based on speed.
  /// - Stopped: 17.0
  /// - Walking: 17.0
  /// - Driving slow: 16.5
  /// - Highway: 16.0
  double get speedBasedZoom {
    final speed = currentSpeed;
    if (speed <= 0) return 17.0;
    if (speed < 5) return 17.0;
    if (speed < 15) return 16.5;
    return 16.0;
  }

  NavigationState copyWith({
    int? currentManeuverIndex,
    bool? isNavigating,
    UserLocation? currentLocation,
    double? distanceToNextManeuver,
    bool? isPreviewMode,
    bool clearLocation = false,
    bool? isRecalculating,
    ValhallaRouteResponse? routeResponse,
    List<Point>? routePoints,
    List<RouteWaypoint>? originalWaypoints,
  }) {
    return NavigationState(
      routeResponse: routeResponse ?? this.routeResponse,
      currentManeuverIndex: currentManeuverIndex ?? this.currentManeuverIndex,
      isNavigating: isNavigating ?? this.isNavigating,
      routePoints: routePoints ?? this.routePoints,
      currentLocation: clearLocation
          ? null
          : (currentLocation ?? this.currentLocation),
      distanceToNextManeuver:
          distanceToNextManeuver ?? this.distanceToNextManeuver,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
      isRecalculating: isRecalculating ?? this.isRecalculating,
      travelMode: travelMode,
      originalWaypoints: originalWaypoints ?? this.originalWaypoints,
    );
  }
}

class NavigationNotifier extends Notifier<NavigationState?> {
  @override
  NavigationState? build() => null;

  /// Start navigation with the given route response and decoded points.
  void startNavigation({
    required ValhallaRouteResponse routeResponse,
    required List<Point> routePoints,
    TravelMode travelMode = TravelMode.auto,
    List<RouteWaypoint> originalWaypoints = const [],
  }) {
    state = NavigationState(
      routeResponse: routeResponse,
      currentManeuverIndex: 0,
      routePoints: routePoints,
      travelMode: travelMode,
      originalWaypoints: originalWaypoints,
    );
  }

  /// Update with the user's live location. Auto-advances maneuvers when
  /// the user is close enough to the end of the current maneuver.
  /// Also triggers off-route recalculation if the user is too far from
  /// the route line.
  void updateUserLocation(UserLocation loc) {
    try {
      _updateUserLocationInternal(loc);
    } catch (e) {
      // Silently ignore individual location update errors to avoid
      // crashing the navigation. The next update will retry.
      debugPrint('updateUserLocation error: $e');
    }
  }

  void _updateUserLocationInternal(UserLocation loc) {
    if (state == null || !state!.isNavigating || state!.isRecalculating) return;

    final maneuver = state!.currentManeuver;
    if (maneuver == null) return;

    final points = state!.routePoints;
    if (points.isEmpty) return;
    final endIndex = maneuver.endShapeIndex.clamp(0, points.length - 1);

    // Compute distance from user to the end of the current maneuver
    final endLat = points[endIndex].coordinates.lat as double;
    final endLng = points[endIndex].coordinates.lng as double;
    final dist = _haversineDistance(
      loc.latitude,
      loc.longitude,
      endLat,
      endLng,
    );

    // --- Off-route detection ---
    final minDistToRoute = _minDistanceToRoute(loc, points, maneuver);
    if (minDistToRoute > kOffRouteThresholdMeters) {
      recalculateRoute(loc);
      // Don't advance maneuvers while recalculating; just update position
      state = state!.copyWith(
        currentLocation: loc,
        distanceToNextManeuver: dist,
      );
      return;
    }

    // Auto-advance if close enough to the end of this maneuver
    if (dist < 30 && !state!.isComplete) {
      final next = state!.currentManeuverIndex + 1;
      if (next < state!.allManeuvers.length) {
        // Check if this is the destination maneuver
        if (state!.allManeuvers[next].type == 4) {
          // Destination reached when within 15m
          if (dist < 15) {
            state = state!.copyWith(
              currentManeuverIndex: next,
              currentLocation: loc,
              distanceToNextManeuver: 0,
              isNavigating: false,
            );
            return;
          }
        } else {
          state = state!.copyWith(
            currentManeuverIndex: next,
            currentLocation: loc,
          );
          return;
        }
      }
    }

    state = state!.copyWith(currentLocation: loc, distanceToNextManeuver: dist);
  }

  /// Advance to the next maneuver (manual / preview mode).
  void nextManeuver() {
    if (state == null) return;
    final next = state!.currentManeuverIndex + 1;
    if (next < state!.allManeuvers.length) {
      state = state!.copyWith(currentManeuverIndex: next);
    }
  }

  /// Go back to previous maneuver (manual / preview mode).
  void previousManeuver() {
    if (state == null) return;
    final prev = state!.currentManeuverIndex - 1;
    if (prev >= 0) {
      state = state!.copyWith(currentManeuverIndex: prev);
    }
  }

  /// Toggle between live GPS mode and manual preview mode.
  void togglePreviewMode() {
    if (state == null) return;
    state = state!.copyWith(
      isPreviewMode: !state!.isPreviewMode,
      clearLocation: !state!.isPreviewMode,
    );
  }

  /// Stop navigation and clear state.
  void stopNavigation() {
    state = null;
  }

  /// Recalculate the route from the user's current position through all
  /// remaining waypoints to the final destination.
  ///
  /// This determines which leg the user is currently on and creates a new
  /// route from [userLoc] → remaining waypoints → destination.
  Future<void> recalculateRoute(UserLocation userLoc) async {
    if (state == null || state!.isRecalculating) return;

    // Mark as recalculating
    state = state!.copyWith(isRecalculating: true);

    try {
      // Determine which leg the user is currently on by counting maneuvers
      // per leg up to the current maneuver index.
      final legs = state!.routeResponse.legs;
      int maneuverCount = 0;
      int currentLegIndex = 0;
      for (int i = 0; i < legs.length; i++) {
        if (state!.currentManeuverIndex <
            maneuverCount + legs[i].maneuvers.length) {
          currentLegIndex = i;
          break;
        }
        maneuverCount += legs[i].maneuvers.length;
        if (i == legs.length - 1) currentLegIndex = i;
      }

      // Build the list of remaining waypoints.
      // If original waypoints are available, use those (from current leg's
      // destination onward). Otherwise, derive from the route geometry.
      List<ValhallaLocation> remainingLocations;

      if (state!.originalWaypoints.isNotEmpty) {
        // Original waypoints: [origin, wp1, wp2, ..., destination]
        // The user is on leg[currentLegIndex], heading toward
        // originalWaypoints[currentLegIndex + 1]. We include all waypoints
        // from currentLegIndex + 1 onward (including destination).
        remainingLocations = [
          ValhallaLocation(
            lat: userLoc.latitude,
            lon: userLoc.longitude,
            type: 'break',
            name: 'Current Location',
          ),
        ];
        for (
          int i = currentLegIndex + 1;
          i < state!.originalWaypoints.length;
          i++
        ) {
          final wp = state!.originalWaypoints[i];
          remainingLocations.add(
            ValhallaLocation(
              lat: wp.lat,
              lon: wp.lon,
              type: 'break',
              name: wp.label.isNotEmpty ? wp.label : null,
            ),
          );
        }
      } else {
        // Fallback: derive waypoints from the last point of each remaining leg
        remainingLocations = [
          ValhallaLocation(
            lat: userLoc.latitude,
            lon: userLoc.longitude,
            type: 'break',
            name: 'Current Location',
          ),
        ];
        for (int i = currentLegIndex + 1; i < legs.length; i++) {
          final legPoints = ValhallaRoutingService.decodePolyline6(
            legs[i].shape,
          );
          if (legPoints.isNotEmpty) {
            final last = legPoints.last;
            remainingLocations.add(
              ValhallaLocation(
                lat: last.coordinates.lat as double,
                lon: last.coordinates.lng as double,
                type: 'break',
              ),
            );
          }
        }
      }

      if (remainingLocations.length < 2) {
        // Only current position, no destination — nothing to route to
        state = state!.copyWith(isRecalculating: false);
        return;
      }

      // Fetch new route
      final newResponse = await ValhallaRoutingService.fetchRoute(
        locations: remainingLocations,
        costing: state!.travelMode,
      );

      final newPoints = newResponse.decodedShape;

      // Replace the route data, reset maneuver index
      if (state != null) {
        state = state!.copyWith(
          routeResponse: newResponse,
          routePoints: newPoints,
          currentManeuverIndex: 0,
          distanceToNextManeuver: 0,
          isRecalculating: false,
        );
      }
    } catch (_) {
      // Recalculation failed — clear the flag so we can try again later
      if (state != null) {
        state = state!.copyWith(isRecalculating: false);
      }
    }
  }

  /// Compute the minimum distance from the user's position to any point on
  /// the current maneuver's route segment. Checks a sampled subset of the
  /// polyline for performance (every ~10m along the segment).
  double _minDistanceToRoute(
    UserLocation loc,
    List<Point> points,
    ValhallaManeuver maneuver,
  ) {
    if (points.isEmpty) return double.infinity;
    final startIndex = maneuver.beginShapeIndex.clamp(0, points.length - 1);
    final endIndex = maneuver.endShapeIndex.clamp(0, points.length - 1);
    if (startIndex >= endIndex) return double.infinity;

    double minDist = double.infinity;
    Point? prevPoint;

    for (int i = startIndex; i <= endIndex; i++) {
      final point = points[i];
      final pLat = point.coordinates.lat as double;
      final pLng = point.coordinates.lng as double;

      final dist = _haversineDistance(loc.latitude, loc.longitude, pLat, pLng);
      if (dist < minDist) minDist = dist;

      // Also check perpendicular distance to the line segment
      if (prevPoint != null) {
        final prevLat = prevPoint.coordinates.lat as double;
        final prevLng = prevPoint.coordinates.lng as double;
        final perpDist = _perpendicularDistance(
          loc.latitude,
          loc.longitude,
          prevLat,
          prevLng,
          pLat,
          pLng,
        );
        if (perpDist < minDist) minDist = perpDist;
      }

      prevPoint = point;
    }

    return minDist;
  }

  /// Approximate perpendicular distance from point (px, py) to the line
  /// segment (x1, y1)→(x2, y2) in meters, using haversine.
  /// Returns the distance to the nearest point on the segment.
  double _perpendicularDistance(
    double px,
    double py,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    // Use a simple linear interpolation ratio (works well for short segments)
    final dx = x2 - x1;
    final dy = y2 - y1;
    if (dx == 0 && dy == 0) {
      return _haversineDistance(px, py, x1, y1);
    }

    // Normalized projection of (px,py) onto the segment
    final lenSq = dx * dx + dy * dy;
    var t = ((px - x1) * dx + (py - y1) * dy) / lenSq;
    t = t.clamp(0.0, 1.0);

    final projLat = x1 + t * dx;
    final projLng = y1 + t * dy;

    return _haversineDistance(px, py, projLat, projLng);
  }

  /// Haversine distance between two lat/lng points in meters.
  double _haversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // meters
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState?>(
      NavigationNotifier.new,
    );
