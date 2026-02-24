import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'trends_constants.dart';

class TrendsService {
  Future<Map<String, dynamic>> get({
    required Session session,
    required String interval,
    required int limit,
  }) async {
    if (!trendsIntervals.containsKey(interval)) {
      return {
        'success': false,
        'error': 'Unsupported interval.',
      };
    }

    final safeLimit = limit.clamp(1, trendsDefaultTopK).toInt();
    final cacheKey = trendsCacheKey(interval);

    final cached = await session.caches.local.get<TrendsSnapshot>(cacheKey);
    if (cached != null) {
      return _limitPayload(cached.payloadJson, safeLimit);
    }

    final snapshot = await TrendsSnapshot.db.findFirstRow(
      session,
      where: (t) => t.interval.equals(interval),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    if (snapshot == null) {
      return {
        'success': true,
        'interval': interval,
        'windowHours': trendsIntervals[interval]!.inHours,
        'bucketMinutes': trendsBucketDuration.inMinutes,
        'generatedAt': null,
        'top': <Map<String, dynamic>>[],
        'limit': safeLimit,
      };
    }

    await session.caches.local.put(
      cacheKey,
      snapshot,
      lifetime: const Duration(seconds: 30),
    );

    return _limitPayload(snapshot.payloadJson, safeLimit);
  }

  Map<String, dynamic> _limitPayload(String payloadJson, int limit) {
    final decoded = jsonDecode(payloadJson);
    final payload = Map<String, dynamic>.from(decoded as Map);
    final top = List<dynamic>.from(payload['top'] as List? ?? const []);
    payload['top'] = top.take(limit).toList();
    payload['limit'] = limit;
    return payload;
  }
}
