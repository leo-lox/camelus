import '../../domain_layer/entities/map_coordinate.dart';
import '../../domain_layer/entities/map_place.dart';
import '../../domain_layer/repositories/place_search_repository.dart';
import '../data_sources/mapbox_place_search_data_source.dart';

class PlaceSearchRepositoryImpl implements PlaceSearchRepository {
  final MapboxPlaceSearchDataSource _dataSource;

  PlaceSearchRepositoryImpl(this._dataSource);

  @override
  Future<List<MapPlace>> search(String query) => _dataSource.search(query);

  @override
  Future<MapPlace?> reverseGeocode(MapCoordinate coordinate) =>
      _dataSource.reverseGeocode(coordinate);
}
