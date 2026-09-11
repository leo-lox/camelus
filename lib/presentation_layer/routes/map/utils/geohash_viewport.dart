import 'package:dart_geohash/dart_geohash.dart';

import '../../../../domain_layer/entities/map_coordinate.dart';

/// Geohash character precision tuned to typical Mapbox zoom levels, so the
/// covered area roughly matches what's visible on screen.
int geohashPrecisionForZoom(double zoom) {
  if (zoom >= 15) return 7;
  if (zoom >= 12) return 6;
  if (zoom >= 9) return 5;
  if (zoom >= 6) return 4;
  if (zoom >= 3) return 3;
  return 2;
}

/// Returns the geohash covering [center] plus its 8 neighbors, at a
/// precision derived from [zoom]. Used to query nearby location reports
/// without loading the whole world.
List<String> geohashesForViewport(MapCoordinate center, double zoom) {
  final precision = geohashPrecisionForZoom(zoom);
  final geoHash = GeoHash.fromDecimalDegrees(
    center.longitude,
    center.latitude,
    precision: precision,
  );
  return {geoHash.geohash, ...geoHash.neighbors.values}.toList();
}
