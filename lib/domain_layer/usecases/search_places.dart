import '../entities/map_place.dart';
import '../repositories/place_search_repository.dart';

class SearchPlaces {
  final PlaceSearchRepository _repository;

  SearchPlaces(this._repository);

  Future<List<MapPlace>> call(String query) => _repository.search(query);
}
