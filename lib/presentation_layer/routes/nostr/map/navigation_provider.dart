import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'live_location_provider.dart';
import 'valhalla_routing_service.dart';

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

  const NavigationState({
    required this.routeResponse,
    required this.currentManeuverIndex,
    this.isNavigating = true,
    required this.routePoints,
    this.currentLocation,
    this.distanceToNextManeuver = 0.0,
    this.isPreviewMode = false,
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
  }) {
    return NavigationState(
      routeResponse: routeResponse,
      currentManeuverIndex: currentManeuverIndex ?? this.currentManeuverIndex,
      isNavigating: isNavigating ?? this.isNavigating,
      routePoints: routePoints,
      currentLocation: clearLocation
          ? null
          : (currentLocation ?? this.currentLocation),
      distanceToNextManeuver:
          distanceToNextManeuver ?? this.distanceToNextManeuver,
      isPreviewMode: isPreviewMode ?? this.isPreviewMode,
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
  }) {
    state = NavigationState(
      routeResponse: routeResponse,
      currentManeuverIndex: 0,
      routePoints: routePoints,
    );
  }

  /// Update with the user's live location. Auto-advances maneuvers when
  /// the user is close enough to the end of the current maneuver.
  void updateUserLocation(UserLocation loc) {
    if (state == null || !state!.isNavigating) return;

    final maneuver = state!.currentManeuver;
    if (maneuver == null) return;

    final points = state!.routePoints;
    final endIndex = maneuver.endShapeIndex.clamp(0, points.length - 1);
    if (endIndex >= points.length) return;

    // Compute distance from user to the end of the current maneuver
    final endLat = points[endIndex].coordinates.lat as double;
    final endLng = points[endIndex].coordinates.lng as double;
    final dist = _haversineDistance(
      loc.latitude,
      loc.longitude,
      endLat,
      endLng,
    );

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
