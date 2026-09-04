import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain_layer/entities/map_coordinate.dart';
import '../../domain_layer/entities/map_place.dart';

class MapboxPlaceSearchDataSource {
  final http.Client _client;
  final String _accessToken;

  MapboxPlaceSearchDataSource(this._client, this._accessToken);

  Future<List<MapPlace>> search(String query) async {
    if (_accessToken.isEmpty) {
      throw StateError('MAPBOX_ACCESS_TOKEN is not configured');
    }
    final uri = Uri.https('api.mapbox.com', '/search/geocode/v6/forward', {
      'q': query,
      'limit': '6',
      'access_token': _accessToken,
    });
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Place search failed with HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return (payload['features'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(_parseFeature)
        .toList(growable: false);
  }

  Future<MapPlace?> reverseGeocode(MapCoordinate coordinate) async {
    if (_accessToken.isEmpty) {
      throw StateError('MAPBOX_ACCESS_TOKEN is not configured');
    }
    final uri = Uri.https('api.mapbox.com', '/search/geocode/v6/reverse', {
      'longitude': coordinate.longitude.toString(),
      'latitude': coordinate.latitude.toString(),
      'limit': '1',
      'access_token': _accessToken,
    });
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Reverse geocoding failed with HTTP ${response.statusCode}',
      );
    }
    final features =
        (jsonDecode(response.body) as Map<String, dynamic>)['features']
            as List<dynamic>?;
    if (features == null || features.isEmpty) return null;
    return _parseFeature(features.first as Map<String, dynamic>);
  }

  static MapPlace _parseFeature(Map<String, dynamic> feature) {
    final coordinates =
        (feature['geometry'] as Map<String, dynamic>)['coordinates']
            as List<dynamic>;
    final properties =
        feature['properties'] as Map<String, dynamic>? ?? const {};
    return MapPlace(
      name:
          properties['name'] as String? ??
          properties['name_preferred'] as String? ??
          feature['name'] as String? ??
          feature['place_name'] as String? ??
          'Unknown place',
      address:
          properties['full_address'] as String? ??
          properties['place_formatted'] as String? ??
          feature['place_name'] as String? ??
          '',
      coordinate: MapCoordinate(
        longitude: (coordinates[0] as num).toDouble(),
        latitude: (coordinates[1] as num).toDouble(),
      ),
    );
  }
}
