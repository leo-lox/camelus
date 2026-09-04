import 'map_coordinate.dart';

enum TravelMode { driving, walking, cycling }

extension TravelModeValhalla on TravelMode {
  String get valhallaCosting => switch (this) {
    TravelMode.driving => 'auto',
    TravelMode.walking => 'pedestrian',
    TravelMode.cycling => 'bicycle',
  };
}

class NavigationManeuver {
  final String instruction;
  final double lengthMeters;
  final Duration duration;
  final MapCoordinate beginCoordinate;

  const NavigationManeuver({
    required this.instruction,
    required this.lengthMeters,
    required this.duration,
    required this.beginCoordinate,
  });
}

class NavigationRoute {
  final List<MapCoordinate> geometry;
  final List<NavigationManeuver> maneuvers;
  final double lengthMeters;
  final Duration duration;

  const NavigationRoute({
    required this.geometry,
    required this.maneuvers,
    required this.lengthMeters,
    required this.duration,
  });
}
