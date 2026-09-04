import '../../domain_layer/entities/map_coordinate.dart';
import '../../domain_layer/entities/navigation_route.dart';
import '../../domain_layer/repositories/directions_repository.dart';
import '../data_sources/valhalla_directions_data_source.dart';

class DirectionsRepositoryImpl implements DirectionsRepository {
  final ValhallaDirectionsDataSource _dataSource;

  DirectionsRepositoryImpl(this._dataSource);

  @override
  Future<NavigationRoute> getRoute({
    required MapCoordinate origin,
    required MapCoordinate destination,
    required TravelMode travelMode,
  }) {
    return _dataSource.getRoute(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
    );
  }
}
