import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/map_coordinate.dart';
import '../../../domain_layer/entities/map_place.dart';
import '../../../domain_layer/entities/navigation_route.dart';
import '../../providers/map_providers.dart';

enum LocationLockStatus {
  permissionNotGiven,
  searching,
  lockedCentered,
  lockedUncentered,
}

class MapState {
  final String query;
  final List<MapPlace> suggestions;
  final MapPlace? destination;
  final MapCoordinate? currentLocation;
  final NavigationRoute? route;
  final TravelMode travelMode;
  final bool isSearching;
  final bool isRouting;
  final bool isLocationSheetOpen;
  final int activeManeuverIndex;
  final LocationLockStatus locationStatus;
  final String? error;

  const MapState({
    this.query = '',
    this.suggestions = const [],
    this.destination,
    this.currentLocation,
    this.route,
    this.travelMode = TravelMode.driving,
    this.isSearching = false,
    this.isRouting = false,
    this.isLocationSheetOpen = false,
    this.activeManeuverIndex = 0,
    this.locationStatus = LocationLockStatus.permissionNotGiven,
    this.error,
  });

  MapState copyWith({
    String? query,
    List<MapPlace>? suggestions,
    MapPlace? destination,
    MapCoordinate? currentLocation,
    NavigationRoute? route,
    TravelMode? travelMode,
    bool? isSearching,
    bool? isRouting,
    bool? isLocationSheetOpen,
    int? activeManeuverIndex,
    LocationLockStatus? locationStatus,
    String? error,
    bool clearDestination = false,
    bool clearRoute = false,
    bool clearError = false,
  }) => MapState(
    query: query ?? this.query,
    suggestions: suggestions ?? this.suggestions,
    destination: clearDestination ? null : destination ?? this.destination,
    currentLocation: currentLocation ?? this.currentLocation,
    route: clearRoute ? null : route ?? this.route,
    travelMode: travelMode ?? this.travelMode,
    isSearching: isSearching ?? this.isSearching,
    isRouting: isRouting ?? this.isRouting,
    isLocationSheetOpen: isLocationSheetOpen ?? this.isLocationSheetOpen,
    activeManeuverIndex: activeManeuverIndex ?? this.activeManeuverIndex,
    locationStatus: locationStatus ?? this.locationStatus,
    error: clearError ? null : error ?? this.error,
  );
}

final mapStateProvider = NotifierProvider<MapStateNotifier, MapState>(
  MapStateNotifier.new,
);

class MapStateNotifier extends Notifier<MapState> {
  Timer? _searchTimer;
  StreamSubscription<MapCoordinate>? _locationSubscription;

  @override
  MapState build() {
    ref.onDispose(() {
      _searchTimer?.cancel();
      _locationSubscription?.cancel();
    });
    return const MapState();
  }

  void setQuery(String query) {
    state = state.copyWith(
      query: query,
      isSearching: query.trim().isNotEmpty,
      clearError: true,
    );
    _searchTimer?.cancel();
    if (query.trim().length < 2) {
      state = state.copyWith(suggestions: const [], isSearching: false);
      return;
    }
    _searchTimer = Timer(
      const Duration(milliseconds: 300),
      () => _search(query),
    );
  }

  Future<void> _search(String query) async {
    try {
      final places = await ref.read(searchPlacesProvider)(query);
      if (state.query == query) {
        state = state.copyWith(suggestions: places, isSearching: false);
      }
    } catch (error) {
      if (state.query == query) {
        state = state.copyWith(isSearching: false, error: error.toString());
      }
    }
  }

  Future<void> selectDestination(MapPlace destination) async {
    state = state.copyWith(
      destination: destination,
      suggestions: const [],
      query: destination.name,
      isLocationSheetOpen: true,
      clearError: true,
    );
  }

  Future<void> selectMapLocation(MapCoordinate coordinate) async {
    final latitude = coordinate.latitude.toStringAsFixed(5);
    final longitude = coordinate.longitude.toStringAsFixed(5);
    state = state.copyWith(
      destination: MapPlace(
        name: 'Dropped pin',
        address: '$latitude, $longitude',
        coordinate: coordinate,
      ),
      suggestions: const [],
      query: '',
      clearRoute: true,
      isLocationSheetOpen: true,
      clearError: true,
    );
    try {
      final place = await ref.read(reverseGeocodeProvider)(coordinate);
      final selectedCoordinate = state.destination?.coordinate;
      if (place == null ||
          selectedCoordinate?.latitude != coordinate.latitude ||
          selectedCoordinate?.longitude != coordinate.longitude) {
        return;
      }
      state = state.copyWith(
        destination: MapPlace(
          name: place.name,
          address: place.address,
          coordinate: coordinate,
        ),
      );
    } catch (_) {
      // Keep the selected coordinate available if reverse geocoding fails.
    }
  }

  void closeLocationSheet() => state = state.copyWith(
    isLocationSheetOpen: false,
    clearDestination: true,
    clearRoute: true,
    query: '',
  );

  void clearError() => state = state.copyWith(clearError: true);

  Future<void> onLocationFabPressed() async {
    if (state.locationStatus == LocationLockStatus.searching) return;

    if (state.locationStatus == LocationLockStatus.permissionNotGiven ||
        state.currentLocation == null) {
      state = state.copyWith(
        locationStatus: LocationLockStatus.searching,
        clearError: true,
      );
      try {
        final hasPermission = await ref
            .read(locationRepositoryProvider)
            .requestPermission();
        if (!hasPermission) {
          state = state.copyWith(
            locationStatus: LocationLockStatus.permissionNotGiven,
            error: 'Location permission required to find your location.',
          );
          return;
        }
        final location = await ref
            .read(locationRepositoryProvider)
            .getCurrentLocation();
        state = state.copyWith(
          currentLocation: location,
          locationStatus: LocationLockStatus.lockedCentered,
          clearError: true,
        );
      } catch (error) {
        state = state.copyWith(
          locationStatus: LocationLockStatus.permissionNotGiven,
          error: error.toString(),
        );
      }
    } else {
      // Location is available: set state to lockedCentered
      state = state.copyWith(
        locationStatus: LocationLockStatus.lockedCentered,
        clearError: true,
      );
    }
  }

  void onMapMovedByUser() {
    if (state.locationStatus == LocationLockStatus.lockedCentered) {
      state = state.copyWith(
        locationStatus: LocationLockStatus.lockedUncentered,
      );
    }
  }

  Future<void> locateUser({bool follow = false}) async {
    await onLocationFabPressed();
    if (follow && state.currentLocation != null) {
      _startLocationUpdates();
    }
  }

  Future<void> calculateRoute() async {
    final origin = state.currentLocation;
    final destination = state.destination;
    if (origin == null || destination == null) return;
    state = state.copyWith(isRouting: true, clearRoute: true, clearError: true);
    try {
      final route = await ref.read(getDirectionsProvider)(
        origin: origin,
        destination: destination.coordinate,
        travelMode: state.travelMode,
      );
      state = state.copyWith(
        route: route,
        isRouting: false,
        activeManeuverIndex: 0,
      );
    } catch (error) {
      state = state.copyWith(isRouting: false, error: error.toString());
    }
  }

  Future<void> setTravelMode(TravelMode travelMode) async {
    state = state.copyWith(travelMode: travelMode);
    await calculateRoute();
  }

  void startNavigation() => _startLocationUpdates();

  void stopNavigation() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    ref.read(navigationVoiceRepositoryProvider).stop();
  }

  void _startLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = ref
        .read(locationRepositoryProvider)
        .watchLocation()
        .listen(
          _onLocationUpdate,
          onError: (Object error) =>
              state = state.copyWith(error: error.toString()),
        );
  }

  void _onLocationUpdate(MapCoordinate location) {
    state = state.copyWith(currentLocation: location);
    final route = state.route;
    if (route == null || route.maneuvers.isEmpty) return;

    final nextIndex = state.activeManeuverIndex + 1;
    if (nextIndex >= route.maneuvers.length) return;
    final nextManeuver = route.maneuvers[nextIndex];
    if (_distanceInMeters(location, nextManeuver.beginCoordinate) > 35) return;

    state = state.copyWith(activeManeuverIndex: nextIndex);
    ref.read(navigationVoiceRepositoryProvider).speak(nextManeuver.instruction);
  }

  double _distanceInMeters(MapCoordinate first, MapCoordinate second) {
    const earthRadiusMeters = 6371000.0;
    final latitudeDelta = _radians(second.latitude - first.latitude);
    final longitudeDelta = _radians(second.longitude - first.longitude);
    final latitude1 = _radians(first.latitude);
    final latitude2 = _radians(second.latitude);
    final haversine =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(latitude1) *
            math.cos(latitude2) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return 2 *
        earthRadiusMeters *
        math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  }

  double _radians(double degrees) => degrees * math.pi / 180;
}
