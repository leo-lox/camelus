import 'package:geolocator/geolocator.dart';

import '../../domain_layer/entities/map_coordinate.dart';

class DeviceLocationDataSource {
  Future<bool> checkPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> requestPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<MapCoordinate> getCurrentLocation() async {
    await _ensurePermission();
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
    return _toCoordinate(position);
  }

  Stream<MapCoordinate> watchLocation() async* {
    await _ensurePermission();
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 8,
      ),
    ).map(_toCoordinate);
  }

  Future<void> _ensurePermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Location services are disabled');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was denied');
    }
  }

  static MapCoordinate _toCoordinate(Position position) =>
      MapCoordinate(latitude: position.latitude, longitude: position.longitude);
}
