import '../entities/map_coordinate.dart';
import '../entities/map_place.dart';
import '../repositories/place_search_repository.dart';

class ReverseGeocode {
  final PlaceSearchRepository _repository;

  ReverseGeocode(this._repository);

  Future<MapPlace?> call(MapCoordinate coordinate) =>
      _repository.reverseGeocode(coordinate);
}
