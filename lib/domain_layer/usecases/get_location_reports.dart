import '../entities/user_location_report.dart';
import '../repositories/location_report_repository.dart';

class GetLocationReports {
  final LocationReportRepository _locationReportRepository;

  GetLocationReports(this._locationReportRepository);

  Stream<UserLocationReport> call({
    required List<String> geohashes,
    required int since,
  }) {
    return _locationReportRepository.getLocationReports(
      geohashes: geohashes,
      since: since,
    );
  }
}
