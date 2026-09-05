import '../entities/map_coordinate.dart';

abstract class LocationRepository {
  Future<bool> checkPermission();

  Future<bool> requestPermission();

  Future<MapCoordinate> getCurrentLocation();

  Stream<MapCoordinate> watchLocation();
}
