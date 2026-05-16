import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'geocoding_service.dart';
import 'valhalla_routing_service.dart';

/// A single waypoint (origin, intermediate stop, or destination).
class RouteWaypoint {
  final double lat;
  final double lon;
  String label;

  RouteWaypoint({required this.lat, required this.lon, this.label = ''});

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon, 'type': 'break'};
}

/// State for the route planning feature.
class RouteState {
  final List<RouteWaypoint> waypoints;
  final TravelMode travelMode;
  final bool isRouting;
  final List<ValhallaRouteResponse> routeResponses;
  final int selectedRouteIndex;
  final String? error;
  final bool isRoutePanelOpen;
  final int focusedWaypointIndex;
  final List<TransitType> transitTypes;

  // Geocoding state per waypoint
  final List<GeocodingResult> geocodingResults;
  final bool isGeocoding;

  const RouteState({
    this.waypoints = const [],
    this.travelMode = TravelMode.auto,
    this.isRouting = false,
    this.routeResponses = const [],
    this.selectedRouteIndex = 0,
    this.error,
    this.isRoutePanelOpen = false,
    this.focusedWaypointIndex = 0,
    this.transitTypes = kDefaultTransitTypes,
    this.geocodingResults = const [],
    this.isGeocoding = false,
  });

  bool get canRoute => waypoints.length >= 2;

  /// The currently selected route response.
  ValhallaRouteResponse? get routeResponse {
    if (routeResponses.isEmpty) return null;
    if (selectedRouteIndex < routeResponses.length) {
      return routeResponses[selectedRouteIndex];
    }
    return routeResponses.first;
  }

  /// Number of available routes (including alternatives).
  int get routeCount => routeResponses.length;

  RouteState copyWith({
    List<RouteWaypoint>? waypoints,
    TravelMode? travelMode,
    bool? isRouting,
    List<ValhallaRouteResponse>? routeResponses,
    int? selectedRouteIndex,
    String? error,
    bool clearError = false,
    bool? isRoutePanelOpen,
    int? focusedWaypointIndex,
    List<TransitType>? transitTypes,
    List<GeocodingResult>? geocodingResults,
    bool? isGeocoding,
    bool clearRouteResponses = false,
  }) {
    return RouteState(
      waypoints: waypoints ?? this.waypoints,
      travelMode: travelMode ?? this.travelMode,
      isRouting: isRouting ?? this.isRouting,
      routeResponses: clearRouteResponses
          ? []
          : (routeResponses ?? this.routeResponses),
      selectedRouteIndex: selectedRouteIndex ?? this.selectedRouteIndex,
      error: clearError ? null : (error ?? this.error),
      isRoutePanelOpen: isRoutePanelOpen ?? this.isRoutePanelOpen,
      focusedWaypointIndex: focusedWaypointIndex ?? this.focusedWaypointIndex,
      transitTypes: transitTypes ?? this.transitTypes,
      geocodingResults: geocodingResults ?? this.geocodingResults,
      isGeocoding: isGeocoding ?? this.isGeocoding,
    );
  }
}

class RouteNotifier extends Notifier<RouteState> {
  @override
  RouteState build() {
    return const RouteState();
  }

  /// Open the route panel and optionally pre-fill the origin from current location.
  void openPanel({double? originLat, double? originLon, String? originLabel}) {
    final waypoints = <RouteWaypoint>[];

    if (originLat != null && originLon != null) {
      waypoints.add(
        RouteWaypoint(
          lat: originLat,
          lon: originLon,
          label: originLabel ?? 'Current location',
        ),
      );
    }
    // Add an empty placeholder for the destination
    waypoints.add(RouteWaypoint(lat: 0, lon: 0, label: ''));

    state = RouteState(
      waypoints: waypoints,
      travelMode: TravelMode.auto,
      isRoutePanelOpen: true,
      focusedWaypointIndex: waypoints.length - 1, // focus destination
    );
  }

  /// Close the route panel and clear route data.
  void closePanel() {
    state = const RouteState();
  }

  /// Set which waypoint input is focused (for geocoding / map tap fill).
  void setFocusedWaypoint(int index) {
    state = state.copyWith(focusedWaypointIndex: index);
  }

  /// Update a waypoint's label (user types a new address).
  void updateWaypointLabel(int index, String label) {
    if (index < 0 || index >= state.waypoints.length) return;
    final updated = List<RouteWaypoint>.from(state.waypoints);
    updated[index] = RouteWaypoint(
      lat: state.waypoints[index].lat,
      lon: state.waypoints[index].lon,
      label: label,
    );
    state = state.copyWith(
      waypoints: updated,
      clearError: true,
      clearRouteResponses: true,
    );
  }

  /// Set a waypoint from a geocoding result.
  void setWaypointFromResult(int index, GeocodingResult result) {
    if (index < 0 || index >= state.waypoints.length) return;
    final updated = List<RouteWaypoint>.from(state.waypoints);
    updated[index] = RouteWaypoint(
      lat: result.lat,
      lon: result.lon,
      label: result.name ?? result.displayName,
    );
    state = state.copyWith(
      waypoints: updated,
      geocodingResults: [],
      clearError: true,
      clearRouteResponses: true,
    );
    _autoFetchRoute();
  }

  /// Set a waypoint from a map tap (lat/lon).
  void setWaypointFromMapTap(
    int index,
    double lat,
    double lon, {
    String? label,
  }) {
    if (index < 0 || index >= state.waypoints.length) return;
    final updated = List<RouteWaypoint>.from(state.waypoints);
    updated[index] = RouteWaypoint(
      lat: lat,
      lon: lon,
      label: label ?? '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
    );
    state = state.copyWith(
      waypoints: updated,
      geocodingResults: [],
      clearError: true,
      clearRouteResponses: true,
    );
    _autoFetchRoute();
  }

  /// Swap origin and destination.
  void swapOriginDestination() {
    if (state.waypoints.length < 2) return;
    final updated = List<RouteWaypoint>.from(state.waypoints);
    final origin = updated[0];
    updated[0] = updated.last;
    updated[updated.length - 1] = origin;
    state = state.copyWith(
      waypoints: updated,
      clearError: true,
      clearRouteResponses: true,
    );
    _autoFetchRoute();
  }

  /// Add an intermediate waypoint.
  void addWaypoint() {
    final updated = [...state.waypoints];
    updated.insert(
      updated.length - 1,
      RouteWaypoint(lat: 0, lon: 0, label: ''),
    );
    state = state.copyWith(
      waypoints: updated,
      focusedWaypointIndex: updated.length - 2,
    );
  }

  /// Remove an intermediate waypoint.
  void removeWaypoint(int index) {
    if (state.waypoints.length <= 2) return; // keep at least origin + dest
    if (index <= 0 || index >= state.waypoints.length - 1)
      return; // don't remove origin/dest
    final updated = List<RouteWaypoint>.from(state.waypoints);
    updated.removeAt(index);
    state = state.copyWith(
      waypoints: updated,
      clearError: true,
      clearRouteResponses: true,
    );
  }

  /// Set the travel mode.
  void setTravelMode(TravelMode mode) {
    state = state.copyWith(
      travelMode: mode,
      clearError: true,
      clearRouteResponses: true,
    );
    _autoFetchRoute();
  }

  /// Toggle a transit type on/off for multimodal routing.
  /// At least one type must remain enabled.
  void toggleTransitType(TransitType type) {
    final current = state.transitTypes;
    final updated = current.contains(type)
        ? current.where((t) => t != type).toList()
        : [...current, type];
    if (updated.isEmpty) return; // keep at least one
    state = state.copyWith(
      transitTypes: updated,
      clearError: true,
      clearRouteResponses: true,
    );
    _autoFetchRoute();
  }

  /// Check if all waypoints have valid coordinates and auto-fetch.
  void _autoFetchRoute() {
    if (!state.canRoute || state.isRouting) return;
    final allValid = state.waypoints.every((wp) => wp.lat != 0 && wp.lon != 0);
    if (allValid) {
      fetchRoute();
    }
  }

  /// Trigger geocoding for the currently focused waypoint.
  Future<void> searchGeocoding(String query, {String? language}) async {
    if (query.trim().length < 2) {
      state = state.copyWith(geocodingResults: []);
      return;
    }

    state = state.copyWith(isGeocoding: true);

    final results = await GeocodingService.search(query, language: language);

    if (state.isRoutePanelOpen) {
      state = state.copyWith(geocodingResults: results, isGeocoding: false);
    }
  }

  /// Fetch routes (including alternatives) using the current waypoints and travel mode.
  Future<void> fetchRoute() async {
    if (!state.canRoute) return;

    state = state.copyWith(
      isRouting: true,
      clearError: true,
      clearRouteResponses: true,
    );

    try {
      final locations = state.waypoints.map((wp) {
        return ValhallaLocation(
          lat: wp.lat,
          lon: wp.lon,
          type: wp.label.isEmpty ? 'break' : 'break',
          name: wp.label.isEmpty ? null : wp.label,
        );
      }).toList();

      final responses = await ValhallaRoutingService.fetchRoutes(
        locations: locations,
        costing: state.travelMode,
        transitTypes: state.transitTypes,
      );

      if (state.isRoutePanelOpen) {
        state = state.copyWith(
          routeResponses: responses,
          selectedRouteIndex: 0,
          isRouting: false,
        );
      }
    } catch (e) {
      if (state.isRoutePanelOpen) {
        state = state.copyWith(error: e.toString(), isRouting: false);
      }
    }
  }

  /// Select a route by index (e.g. tapping an alternative on the map).
  void selectRoute(int index) {
    if (index < 0 || index >= state.routeResponses.length) return;
    state = state.copyWith(selectedRouteIndex: index);
  }
}

final routeProvider = NotifierProvider<RouteNotifier, RouteState>(
  RouteNotifier.new,
);
