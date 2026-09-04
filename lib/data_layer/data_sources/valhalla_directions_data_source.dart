import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain_layer/entities/map_coordinate.dart';
import '../../domain_layer/entities/navigation_route.dart';

class ValhallaDirectionsDataSource {
  final http.Client _client;
  final String _baseUrl;

  ValhallaDirectionsDataSource(this._client, this._baseUrl);

  Future<NavigationRoute> getRoute({
    required MapCoordinate origin,
    required MapCoordinate destination,
    required TravelMode travelMode,
  }) async {
    final response = await _client.get(
      Uri.parse('${_baseUrl.replaceFirst(RegExp(r'/$'), '')}/route').replace(
        queryParameters: {
          'json': jsonEncode({
            'locations': [
              origin.toValhallaJson(),
              destination.toValhallaJson(),
            ],
            'costing': travelMode.valhallaCosting,
            'units': 'kilometers',
          }),
        },
      ),
      headers: const {'Accept': 'application/json'},
    );

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || payload.containsKey('error')) {
      throw Exception(
        payload['error']?['message'] ?? 'Unable to calculate route',
      );
    }

    return parseRoute(payload);
  }

  static NavigationRoute parseRoute(Map<String, dynamic> payload) {
    final trip = payload['trip'] as Map<String, dynamic>?;
    final legs = trip?['legs'] as List<dynamic>?;
    if (trip == null || legs == null || legs.isEmpty) {
      throw const FormatException('Valhalla response has no route legs');
    }

    final geometry = <MapCoordinate>[];
    final maneuvers = <NavigationManeuver>[];
    for (final legJson in legs.cast<Map<String, dynamic>>()) {
      geometry.addAll(_decodePolyline(legJson['shape'] as String));
      for (final maneuverJson
          in (legJson['maneuvers'] as List<dynamic>? ?? const <dynamic>[])
              .cast<Map<String, dynamic>>()) {
        final beginShapeIndex = maneuverJson['begin_shape_index'] as int? ?? 0;
        maneuvers.add(
          NavigationManeuver(
            instruction: maneuverJson['instruction'] as String? ?? '',
            lengthMeters: ((maneuverJson['length'] as num?) ?? 0) * 1000,
            duration: Duration(
              seconds: ((maneuverJson['time'] as num?) ?? 0).round(),
            ),
            beginCoordinate:
                geometry[beginShapeIndex.clamp(0, geometry.length - 1)],
          ),
        );
      }
    }

    return NavigationRoute(
      geometry: geometry,
      maneuvers: maneuvers,
      lengthMeters:
          ((trip['summary'] as Map<String, dynamic>?)?['length'] as num? ?? 0) *
          1000,
      duration: Duration(
        seconds:
            (((trip['summary'] as Map<String, dynamic>?)?['time'] as num?) ?? 0)
                .round(),
      ),
    );
  }

  static List<MapCoordinate> _decodePolyline(String encoded) {
    final coordinates = <MapCoordinate>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      final latitudeResult = _decodeValue(encoded, index);
      latitude += latitudeResult.value;
      index = latitudeResult.nextIndex;
      final longitudeResult = _decodeValue(encoded, index);
      longitude += longitudeResult.value;
      index = longitudeResult.nextIndex;
      coordinates.add(
        MapCoordinate(latitude: latitude / 1e6, longitude: longitude / 1e6),
      );
    }
    return coordinates;
  }

  static ({int value, int nextIndex}) _decodeValue(String encoded, int index) {
    var result = 0;
    var shift = 0;
    int byte;
    do {
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20 && index < encoded.length);
    return (
      value: (result & 1) == 1 ? ~(result >> 1) : result >> 1,
      nextIndex: index,
    );
  }
}
