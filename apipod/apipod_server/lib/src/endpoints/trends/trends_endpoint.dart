import 'package:serverpod/serverpod.dart';
import 'trends_constants.dart';
import 'trends_service.dart';

class TrendsEndpoint extends Endpoint {
  final TrendsService _service = TrendsService();

  Future<Map<String, dynamic>> trends(
    Session session, {
    String interval = '24h',
    int limit = trendsDefaultTopK,
  }) async {
    return _service.get(session: session, interval: interval, limit: limit);
  }
}
