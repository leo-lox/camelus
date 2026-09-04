import '../entities/map_coordinate.dart';
import '../entities/navigation_route.dart';
import '../repositories/directions_repository.dart';

class GetDirections {
  final DirectionsRepository _repository;

  GetDirections(this._repository);

  Future<NavigationRoute> call({
    required MapCoordinate origin,
    required MapCoordinate destination,
    required TravelMode travelMode,
  }) {
    return _repository.getRoute(
      origin: origin,
      destination: destination,
      travelMode: travelMode,
    );
  }
}
