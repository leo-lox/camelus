import '../entities/map_coordinate.dart';
import '../entities/navigation_route.dart';

abstract class DirectionsRepository {
  Future<NavigationRoute> getRoute({
    required MapCoordinate origin,
    required MapCoordinate destination,
    required TravelMode travelMode,
  });
}
