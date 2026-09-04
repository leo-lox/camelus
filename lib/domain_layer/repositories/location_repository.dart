import '../entities/map_coordinate.dart';

abstract class LocationRepository {
  Future<MapCoordinate> getCurrentLocation();

  Stream<MapCoordinate> watchLocation();
}
