import 'map_coordinate.dart';

class MapPlace {
  final String name;
  final String address;
  final MapCoordinate coordinate;

  const MapPlace({
    required this.name,
    required this.address,
    required this.coordinate,
  });
}
