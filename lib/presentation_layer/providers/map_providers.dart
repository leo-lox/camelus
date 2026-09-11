import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod/riverpod.dart';

import '../../data_layer/data_sources/dart_ndk_source.dart';
import '../../data_layer/data_sources/device_location_data_source.dart';
import '../../data_layer/data_sources/mapbox_place_search_data_source.dart';
import '../../data_layer/data_sources/valhalla_directions_data_source.dart';
import '../../data_layer/repositories/directions_repository_impl.dart';
import '../../data_layer/repositories/location_report_repository_impl.dart';
import '../../data_layer/repositories/location_repository_impl.dart';
import '../../data_layer/repositories/navigation_voice_repository_impl.dart';
import '../../data_layer/repositories/place_search_repository_impl.dart';
import '../../domain_layer/repositories/directions_repository.dart';
import '../../domain_layer/repositories/location_report_repository.dart';
import '../../domain_layer/repositories/location_repository.dart';
import '../../domain_layer/repositories/navigation_voice_repository.dart';
import '../../domain_layer/repositories/place_search_repository.dart';
import '../../domain_layer/usecases/get_directions.dart';
import '../../domain_layer/usecases/get_location_reports.dart';
import '../../domain_layer/usecases/reverse_geocode.dart';
import '../../domain_layer/usecases/search_places.dart';
import 'ndk_provider.dart';

final mapboxAccessTokenProvider = Provider<String>(
  (ref) => const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
);

final valhallaBaseUrlProvider = Provider<String>(
  (ref) => const String.fromEnvironment(
    'VALHALLA_BASE_URL',
    defaultValue: 'https://valhalla1.openstreetmap.de',
  ),
);

final mapHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final placeSearchRepositoryProvider = Provider<PlaceSearchRepository>((ref) {
  return PlaceSearchRepositoryImpl(
    MapboxPlaceSearchDataSource(
      ref.watch(mapHttpClientProvider),
      ref.watch(mapboxAccessTokenProvider),
    ),
  );
});

final searchPlacesProvider = Provider<SearchPlaces>((ref) {
  return SearchPlaces(ref.watch(placeSearchRepositoryProvider));
});

final reverseGeocodeProvider = Provider<ReverseGeocode>((ref) {
  return ReverseGeocode(ref.watch(placeSearchRepositoryProvider));
});

final directionsRepositoryProvider = Provider<DirectionsRepository>((ref) {
  return DirectionsRepositoryImpl(
    ValhallaDirectionsDataSource(
      ref.watch(mapHttpClientProvider),
      ref.watch(valhallaBaseUrlProvider),
    ),
  );
});

final getDirectionsProvider = Provider<GetDirections>((ref) {
  return GetDirections(ref.watch(directionsRepositoryProvider));
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepositoryImpl(DeviceLocationDataSource());
});

final navigationVoiceRepositoryProvider = Provider<NavigationVoiceRepository>((
  ref,
) {
  final repository = NavigationVoiceRepositoryImpl(FlutterTts());
  ref.onDispose(repository.stop);
  return repository;
});

final locationReportRepositoryProvider = Provider<LocationReportRepository>((
  ref,
) {
  final ndk = ref.watch(ndkProvider);
  return LocationReportRepositoryImpl(DartNdkSource(ndk));
});

final getLocationReportsProvider = Provider<GetLocationReports>((ref) {
  return GetLocationReports(ref.watch(locationReportRepositoryProvider));
});
