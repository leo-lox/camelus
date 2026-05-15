import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

/// Supported travel/costing modes for Valhalla routing.
enum TravelMode {
  auto('auto'),
  bicycle('bicycle'),
  pedestrian('pedestrian'),
  multimodal('multimodal');

  const TravelMode(this.value);
  final String value;
}

/// A Valhalla route request payload.
class ValhallaRouteRequest {
  final List<ValhallaLocation> locations;
  final TravelMode costing;
  final String units;
  final String language;

  const ValhallaRouteRequest({
    required this.locations,
    required this.costing,
    this.units = 'kilometers',
    this.language = 'en',
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'locations': locations.map((l) => l.toJson()).toList(),
      'costing': costing.value,
      'units': units,
      'language': language,
      'alternates': 3,
    };

    // Multimodal/transit requires a date_time parameter.
    if (costing == TravelMode.multimodal) {
      json['date_time'] = {'type': 0}; // 0 = depart now
    }

    return json;
  }
}

/// A location in a Valhalla route request.
class ValhallaLocation {
  final double lat;
  final double lon;
  final String? type;
  final String? name;

  const ValhallaLocation({
    required this.lat,
    required this.lon,
    this.type,
    this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      if (type != null) 'type': type,
      if (name != null) 'name': name,
    };
  }
}

/// A single maneuver (turn instruction) in a route leg.
class ValhallaManeuver {
  final int type;
  final String instruction;
  final double time;
  final double length;
  final int beginShapeIndex;
  final int endShapeIndex;
  final String? travelMode;
  final List<String>? streetNames;

  const ValhallaManeuver({
    required this.type,
    required this.instruction,
    required this.time,
    required this.length,
    required this.beginShapeIndex,
    required this.endShapeIndex,
    this.travelMode,
    this.streetNames,
  });

  factory ValhallaManeuver.fromJson(Map<String, dynamic> json) {
    return ValhallaManeuver(
      type: json['type'] as int? ?? 0,
      instruction: json['instruction'] as String? ?? '',
      time: (json['time'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      beginShapeIndex: json['begin_shape_index'] as int? ?? 0,
      endShapeIndex: json['end_shape_index'] as int? ?? 0,
      travelMode: json['travel_mode'] as String?,
      streetNames: (json['street_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }
}

/// Summary of a route leg or the entire trip.
class ValhallaSummary {
  final double time; // seconds
  final double length; // in the requested units (km or mi)
  final double? minLat;
  final double? minLon;
  final double? maxLat;
  final double? maxLon;

  const ValhallaSummary({
    required this.time,
    required this.length,
    this.minLat,
    this.minLon,
    this.maxLat,
    this.maxLon,
  });

  factory ValhallaSummary.fromJson(Map<String, dynamic> json) {
    return ValhallaSummary(
      time: (json['time'] as num?)?.toDouble() ?? 0.0,
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      minLat: (json['min_lat'] as num?)?.toDouble(),
      minLon: (json['min_lon'] as num?)?.toDouble(),
      maxLat: (json['max_lat'] as num?)?.toDouble(),
      maxLon: (json['max_lon'] as num?)?.toDouble(),
    );
  }
}

/// A single leg of a route (between two break locations).
class ValhallaLeg {
  final ValhallaSummary summary;
  final String shape; // encoded polyline6
  final List<ValhallaManeuver> maneuvers;

  const ValhallaLeg({
    required this.summary,
    required this.shape,
    required this.maneuvers,
  });

  factory ValhallaLeg.fromJson(Map<String, dynamic> json) {
    return ValhallaLeg(
      summary: ValhallaSummary.fromJson(
        json['summary'] as Map<String, dynamic>,
      ),
      shape: json['shape'] as String? ?? '',
      maneuvers:
          (json['maneuvers'] as List<dynamic>?)
              ?.map((m) => ValhallaManeuver.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// The full Valhalla route response (trip).
class ValhallaRouteResponse {
  final String? statusCode;
  final String? statusMessage;
  final ValhallaSummary tripSummary;
  final List<ValhallaLeg> legs;

  const ValhallaRouteResponse({
    this.statusCode,
    this.statusMessage,
    required this.tripSummary,
    required this.legs,
  });

  factory ValhallaRouteResponse.fromJson(Map<String, dynamic> json) {
    final trip = json['trip'] as Map<String, dynamic>? ?? json;
    return ValhallaRouteResponse(
      statusCode: trip['status']?.toString(),
      statusMessage: trip['status_message'] as String?,
      tripSummary: ValhallaSummary.fromJson(
        trip['summary'] as Map<String, dynamic>,
      ),
      legs:
          (trip['legs'] as List<dynamic>?)
              ?.map((l) => ValhallaLeg.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Whether the route was successful (status 0).
  bool get isSuccess => statusCode == '0';

  /// The combined encoded polyline shape from all legs.
  String get fullShape => legs.map((l) => l.shape).join('');
}

/// Valhalla routing service using the public API.
///
/// Uses https://valhalla1.openstreetmap.de/ for testing.
class ValhallaRoutingService {
  static const String _baseUrl = 'https://valhalla1.openstreetmap.de';

  /// Fetch a route between the given locations.
  static Future<ValhallaRouteResponse> fetchRoute({
    required List<ValhallaLocation> locations,
    required TravelMode costing,
    String units = 'kilometers',
    String language = 'en',
  }) async {
    if (locations.length < 2) {
      throw ArgumentError('At least 2 locations are required');
    }

    final request = ValhallaRouteRequest(
      locations: locations,
      costing: costing,
      units: units,
      language: language,
    );

    final uri = Uri.parse('$_baseUrl/route');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Valhalla routing failed: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);

    // Check for Valhalla error codes
    if (body.containsKey('error_code')) {
      throw Exception(
        'Valhalla error: ${body['error_code']} - ${body['error'] ?? 'Unknown error'}',
      );
    }

    return ValhallaRouteResponse.fromJson(body);
  }

  /// Fetch routes including alternatives.
  ///
  /// Returns a list of [ValhallaRouteResponse] — index 0 is the optimal
  /// route, subsequent entries are alternatives.
  static Future<List<ValhallaRouteResponse>> fetchRoutes({
    required List<ValhallaLocation> locations,
    required TravelMode costing,
    String units = 'kilometers',
    String language = 'en',
  }) async {
    if (locations.length < 2) {
      throw ArgumentError('At least 2 locations are required');
    }

    final request = ValhallaRouteRequest(
      locations: locations,
      costing: costing,
      units: units,
      language: language,
    );

    final uri = Uri.parse('$_baseUrl/route');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Valhalla routing failed: ${response.statusCode} ${response.body}',
      );
    }

    final Map<String, dynamic> body = jsonDecode(response.body);

    // Check for Valhalla error codes
    if (body.containsKey('error_code')) {
      throw Exception(
        'Valhalla error: ${body['error_code']} - ${body['error'] ?? 'Unknown error'}',
      );
    }

    // Parse alternatives: Valhalla returns an 'alternates' array
    // alongside the main 'trip' object. Each element is {trip: {...}}.
    final routes = <ValhallaRouteResponse>[];

    // The primary route is always in 'trip'
    routes.add(ValhallaRouteResponse.fromJson(body));

    // Alternatives are in body['alternates'] (list of {trip: ...} objects)
    final alts = body['alternates'] as List<dynamic>?;
    if (alts != null) {
      for (final alt in alts) {
        routes.add(ValhallaRouteResponse.fromJson({'trip': alt['trip']}));
      }
    }

    return routes;
  }

  /// Decode a Valhalla encoded polyline6 string into a list of [Point]s.
  ///
  /// Valhalla uses Google's encoded polyline algorithm with 6 decimal digit
  /// precision (polyline6).
  static List<Point> decodePolyline6(String encoded) {
    if (encoded.isEmpty) return [];

    final List<Point> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int result = 0;
      int shift = 0;
      int b;

      // Decode latitude
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      lat += ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);

      // Decode longitude
      result = 0;
      shift = 0;

      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);

      lng += ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);

      points.add(Point(coordinates: Position(lng / 1e6, lat / 1e6)));
    }

    return points;
  }
}
