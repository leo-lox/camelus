import 'dart:convert';
import 'package:http/http.dart' as http;

/// A single geocoding result from Nominatim.
class GeocodingResult {
  final double lat;
  final double lon;
  final String displayName;
  final String? name;

  const GeocodingResult({
    required this.lat,
    required this.lon,
    required this.displayName,
    this.name,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final name =
        json['name'] as String? ??
        json['address']?['road'] as String? ??
        json['address']?['name'] as String?;

    return GeocodingResult(
      lat: double.parse(json['lat'] as String),
      lon: double.parse(json['lon'] as String),
      displayName: json['display_name'] as String,
      name: name,
    );
  }
}

/// Geocoding service using the Nominatim (OpenStreetMap) API.
///
/// Rate-limited to 1 request per second as required by Nominatim's usage policy.
class GeocodingService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const int _maxResults = 5;

  /// Throttle: minimum milliseconds between requests.
  static DateTime? _lastRequestTime;
  static const Duration _minInterval = Duration(seconds: 1);

  /// Search for places by query string.
  ///
  /// Returns up to [limit] results. Optionally biases results to a [viewbox]
  /// defined as "x1,y1,x2,y2" (lon1,lat1,lon2,lat2).
  /// [language] should be an IETF BCP 47 language tag (e.g. "en", "de").
  static Future<List<GeocodingResult>> search(
    String query, {
    int limit = _maxResults,
    String? language,
    String? viewbox,
  }) async {
    if (query.trim().length < 2) return [];

    // Throttle to 1 req/sec
    if (_lastRequestTime != null) {
      final elapsed = DateTime.now().difference(_lastRequestTime!);
      if (elapsed < _minInterval) {
        await Future.delayed(_minInterval - elapsed);
      }
    }
    _lastRequestTime = DateTime.now();

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': query,
        'format': 'jsonv2',
        'limit': limit.toString(),
        'addressdetails': '1',
        if (language != null) 'accept-language': language,
        if (viewbox != null) 'viewbox': viewbox,
      },
    );

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'Camelus/1.0 (routing-feature)'},
      );

      if (response.statusCode != 200) return [];

      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((json) => GeocodingResult.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
