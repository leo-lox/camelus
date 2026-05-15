import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TappedLocation {
  final double lat;
  final double lng;
  final String? address;
  final String? poiName;
  final String? poiCategory;
  final String? poiGroup;

  const TappedLocation({
    required this.lat,
    required this.lng,
    this.address,
    this.poiName,
    this.poiCategory,
    this.poiGroup,
  });

  Point get point => Point(coordinates: Position(lng, lat));

  bool get isPoi => poiName != null;

  TappedLocation copyWith({String? address}) {
    return TappedLocation(
      lat: lat,
      lng: lng,
      address: address ?? this.address,
      poiName: poiName,
      poiCategory: poiCategory,
      poiGroup: poiGroup,
    );
  }
}

class MapLocationState {
  final TappedLocation? selectedLocation;
  final bool isSheetOpen;
  final bool isReverseGeocoding;

  const MapLocationState({
    this.selectedLocation,
    this.isSheetOpen = false,
    this.isReverseGeocoding = false,
  });

  MapLocationState copyWith({
    TappedLocation? selectedLocation,
    bool? isSheetOpen,
    bool? isReverseGeocoding,
    bool clearLocation = false,
  }) {
    return MapLocationState(
      selectedLocation: clearLocation
          ? null
          : (selectedLocation ?? this.selectedLocation),
      isSheetOpen: isSheetOpen ?? this.isSheetOpen,
      isReverseGeocoding: isReverseGeocoding ?? this.isReverseGeocoding,
    );
  }
}

class MapLocationNotifier extends Notifier<MapLocationState> {
  @override
  MapLocationState build() {
    return const MapLocationState();
  }

  void onMapTapped(
    double lat,
    double lng, {
    String? poiName,
    String? poiCategory,
    String? poiGroup,
  }) {
    final hasPoi = poiName != null;
    state = MapLocationState(
      selectedLocation: TappedLocation(
        lat: lat,
        lng: lng,
        poiName: poiName,
        poiCategory: poiCategory,
        poiGroup: poiGroup,
      ),
      isSheetOpen: true,
      isReverseGeocoding: !hasPoi,
    );
    if (!hasPoi) {
      _reverseGeocode(lat, lng);
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    // TODO: Integrate with a reverse geocoding service (e.g. Mapbox Geocoding API)
    // For now, just show the coordinates.
    // Example with mapbox_search or http:
    // final response = await http.get(Uri.parse(
    //   'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$token',
    // ));
    await Future.delayed(const Duration(milliseconds: 500));
    if (state.selectedLocation != null &&
        state.selectedLocation!.lat == lat &&
        state.selectedLocation!.lng == lng) {
      state = state.copyWith(
        selectedLocation: state.selectedLocation!.copyWith(
          address: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
        ),
        isReverseGeocoding: false,
      );
    }
  }

  void dismissSheet() {
    state = state.copyWith(isSheetOpen: false);
    Future.delayed(const Duration(milliseconds: 300), () {
      state = state.copyWith(clearLocation: true);
    });
  }
}

final mapLocationProvider =
    NotifierProvider<MapLocationNotifier, MapLocationState>(
      MapLocationNotifier.new,
    );
