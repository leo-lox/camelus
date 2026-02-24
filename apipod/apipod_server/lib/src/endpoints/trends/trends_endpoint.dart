import 'package:serverpod/serverpod.dart';
import '../../generated/protocol.dart';
import 'trends_constants.dart';
import 'trends_service.dart';

class TrendsEndpoint extends Endpoint {
  final TrendsService _service = TrendsService();

  Future<TrendsResponse> trends(
    Session session, {
    String interval = '24h',
    int limit = trendsDefaultTopK,
  }) async {
    return _service.getTrends(
      session: session,
      interval: interval,
      limit: limit,
    );
  }

  Future<TrendsResponse> trendingPeople(
    Session session, {
    String interval = '24h',
    int limit = trendsDefaultTopK,
  }) async {
    return _service.getTrendingPeople(
      session: session,
      interval: interval,
      limit: limit,
    );
  }
}
