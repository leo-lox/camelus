import '../entities/user_location_report.dart';

abstract class LocationReportRepository {
  /// Streams user location reports tagged with any of [geohashes], created
  /// after [since] (unix seconds).
  Stream<UserLocationReport> getLocationReports({
    required List<String> geohashes,
    required int since,
  });
}
