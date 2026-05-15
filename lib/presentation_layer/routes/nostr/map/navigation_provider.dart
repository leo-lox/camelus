import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'valhalla_routing_service.dart';

/// State for the active navigation session.
class NavigationState {
  final ValhallaRouteResponse routeResponse;
  final int currentManeuverIndex;
  final bool isNavigating;
  final List<Point> routePoints;

  const NavigationState({
    required this.routeResponse,
    required this.currentManeuverIndex,
    this.isNavigating = true,
    required this.routePoints,
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

  NavigationState copyWith({int? currentManeuverIndex, bool? isNavigating}) {
    return NavigationState(
      routeResponse: routeResponse,
      currentManeuverIndex: currentManeuverIndex ?? this.currentManeuverIndex,
      isNavigating: isNavigating ?? this.isNavigating,
      routePoints: routePoints,
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

  /// Advance to the next maneuver.
  void nextManeuver() {
    if (state == null) return;
    final next = state!.currentManeuverIndex + 1;
    if (next < state!.allManeuvers.length) {
      state = state!.copyWith(currentManeuverIndex: next);
    }
  }

  /// Go back to previous maneuver.
  void previousManeuver() {
    if (state == null) return;
    final prev = state!.currentManeuverIndex - 1;
    if (prev >= 0) {
      state = state!.copyWith(currentManeuverIndex: prev);
    }
  }

  /// Stop navigation and clear state.
  void stopNavigation() {
    state = null;
  }
}

final navigationProvider =
    NotifierProvider<NavigationNotifier, NavigationState?>(
      NavigationNotifier.new,
    );
