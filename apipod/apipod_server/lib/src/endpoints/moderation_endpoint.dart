import 'package:serverpod/serverpod.dart';

import '../generated/bloom_filter_profiles.dart';

///    'size': <int>,
///    'numHashFunctions': <int>,
///    'bitArray': <string>,
class ModerationEndpoint extends Endpoint {
  Future<Map<String, dynamic>?> getProfileBloomFilter(Session session) async {
    final cacheKey = 'bloom-filter-profiles';
    var bloomFilter =
        await session.caches.local.get<BloomFilterProfile>(cacheKey);

    if (bloomFilter == null) {
      bloomFilter = await BloomFilterProfile.db.findFirstRow(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
      if (bloomFilter != null) {
        await session.caches.local
            .put(cacheKey, bloomFilter, lifetime: Duration(minutes: 10));
      }
    }
    if (bloomFilter == null) {
      return null;
    }

    return {
      "size": bloomFilter.size,
      "numHashFunctions": bloomFilter.numHashFunctions,
      "bitArray": bloomFilter.bitArray,
      "createdAt": bloomFilter.createdAt,
    };
  }
}
