import '../../domain_layer/entities/map_coordinate.dart';
import '../../domain_layer/repositories/location_repository.dart';
import '../data_sources/device_location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final DeviceLocationDataSource _dataSource;

  LocationRepositoryImpl(this._dataSource);

  @override
  Future<MapCoordinate> getCurrentLocation() =>
      _dataSource.getCurrentLocation();

  @override
  Stream<MapCoordinate> watchLocation() => _dataSource.watchLocation();
}
