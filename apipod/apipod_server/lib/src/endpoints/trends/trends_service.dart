import 'dart:convert';

import 'package:serverpod/serverpod.dart';

import '../../generated/protocol.dart';
import 'trends_constants.dart';

class TrendsService {
  Future<TrendsResponse> getTrends({
    required Session session,
    required String interval,
    required int limit,
  }) {
    return _get(
      session: session,
      interval: interval,
      limit: limit,
      includeTop: true,
      includePeople: false,
    );
  }

  Future<TrendsResponse> getTrendingPeople({
    required Session session,
    required String interval,
    required int limit,
  }) {
    return _get(
      session: session,
      interval: interval,
      limit: limit,
      includeTop: false,
      includePeople: true,
    );
  }

  Future<TrendsResponse> _get({
    required Session session,
    required String interval,
    required int limit,
    required bool includeTop,
    required bool includePeople,
  }) async {
    if (!trendsIntervals.containsKey(interval)) {
      return TrendsResponse(
        success: false,
        error: 'Unsupported interval.',
        interval: interval,
        windowHours: null,
        bucketMinutes: null,
        generatedAt: null,
        top: const <TrendsTopItem>[],
        people: const <TrendsTopItem>[],
        limit: null,
      );
    }

    final safeLimit = limit.clamp(1, trendsDefaultTopK).toInt();
    final cacheKey = trendsCacheKey(interval);

    final cached = await session.caches.local.get<TrendsSnapshot>(cacheKey);
    if (cached != null) {
      return _limitPayload(
        cached.payloadJson,
        safeLimit,
        includeTop: includeTop,
        includePeople: includePeople,
      );
    }

    final snapshot = await TrendsSnapshot.db.findFirstRow(
      session,
      where: (t) => t.interval.equals(interval),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );

    if (snapshot == null) {
      return TrendsResponse(
        success: true,
        error: null,
        interval: interval,
        windowHours: trendsIntervals[interval]!.inHours,
        bucketMinutes: trendsBucketDuration.inMinutes,
        generatedAt: null,
        top: const <TrendsTopItem>[],
        people: const <TrendsTopItem>[],
        limit: safeLimit,
      );
    }

    await session.caches.local.put(
      cacheKey,
      snapshot,
      lifetime: const Duration(seconds: 30),
    );

    return _limitPayload(
      snapshot.payloadJson,
      safeLimit,
      includeTop: includeTop,
      includePeople: includePeople,
    );
  }

  TrendsResponse _limitPayload(
    String payloadJson,
    int limit, {
    required bool includeTop,
    required bool includePeople,
  }) {
    final decoded = jsonDecode(payloadJson);
    final payload = Map<String, dynamic>.from(decoded as Map);
    final List<TrendsTopItem> top = includeTop
        ? _parseTopItems(payload['top'], limit)
        : const <TrendsTopItem>[];
    final List<TrendsTopItem> people = includePeople
        ? _parseTopItems(payload['people'], limit)
        : const <TrendsTopItem>[];

    final generatedAtRaw = payload['generatedAt'];
    DateTime? generatedAt;
    if (generatedAtRaw is String && generatedAtRaw.isNotEmpty) {
      generatedAt = DateTime.tryParse(generatedAtRaw)?.toUtc();
    }

    return TrendsResponse(
      success: payload['success'] as bool? ?? true,
      error: payload['error'] as String?,
      interval: payload['interval'] as String?,
      windowHours: (payload['windowHours'] as num?)?.toInt(),
      bucketMinutes: (payload['bucketMinutes'] as num?)?.toInt(),
      generatedAt: generatedAt,
      top: top,
      people: people,
      limit: limit,
    );
  }

  List<TrendsTopItem> _parseTopItems(dynamic source, int limit) {
    final raw = List<dynamic>.from(source as List? ?? const []);
    return raw.take(limit).map((entry) {
      final item = Map<String, dynamic>.from(entry as Map);
      return TrendsTopItem(
        tag: item['tag'] as String? ?? '',
        count: (item['count'] as num?)?.toInt() ?? 0,
      );
    }).toList(growable: false);
  }
}
