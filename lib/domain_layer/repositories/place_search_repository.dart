import '../entities/map_coordinate.dart';
import '../entities/map_place.dart';

abstract class PlaceSearchRepository {
  Future<List<MapPlace>> search(String query);

  Future<MapPlace?> reverseGeocode(MapCoordinate coordinate);
}
