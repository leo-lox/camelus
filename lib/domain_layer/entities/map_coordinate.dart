class MapCoordinate {
  final double latitude;
  final double longitude;

  const MapCoordinate({required this.latitude, required this.longitude});

  Map<String, double> toValhallaJson() => {'lat': latitude, 'lon': longitude};
}
