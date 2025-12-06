import 'dart:convert';

import 'package:ndk/ndk.dart' hide LogLevel;
import 'package:ndk/shared/bloom_filter/bloom_filter_prehash.dart';

import 'package:serverpod/serverpod.dart';

import '../../config/service_config.dart';
import '../../generated/bloom_filter_events.dart';
import '../../generated/bloom_filter_profiles.dart';
import 'moderation_endpoint.dart';

class ProcessReport {
  static final _bloomFalsePositiveProbability = 0.001;
  static final _bloomNumItems = 100000;

  Future<String> processEvent({
    required Nip01Event event,
    required Session session,
    required bool isEventReport,
  }) async {
    if (!ServiceConfig.trustedPubkeys.contains(event.pubKey)) {
      session.log("error: untrusted public key", level: LogLevel.warning);
      return "error: untrusted public key";
    }

    // load bloom
    BloomFilterPrehash loadedBloom = await loadBloomFilter(
      session,
      isEventReport,
    );

    // modify bloom
    String? tag = isEventReport ? event.getEId() : event.getFirstTag('p');
    if (tag != null) {
      loadedBloom.add(tag);
    } else {
      final errMsg =
          isEventReport ? "error no e tag found" : "error no p tag found";

      session.log(errMsg, level: LogLevel.warning);
      return errMsg;
    }

    // save bloom
    await saveBloomFilter(
      session: session,
      isEventReport: isEventReport,
      newBloomFilter: loadedBloom,
    );

    // invalidate cache
    if (isEventReport) {
      await session.caches.local.invalidateKey(
        ModerationEndpoint.cacheKeyEvents,
      );
    } else {
      await session.caches.local.invalidateKey(
        ModerationEndpoint.cacheKeyProfiles,
      );
    }

    session.log("updated bloom filter", level: LogLevel.info);
    return "ok";
  }

  Future<void> saveBloomFilter({
    required Session session,
    required bool isEventReport,
    required BloomFilterPrehash newBloomFilter,
  }) async {
    DateTime now = DateTime.now();

    if (isEventReport) {
      await BloomFilterEvent.db.insertRow(
        session,
        BloomFilterEvent(
          createdAt: now,
          bitArray: newBloomFilter.serialize(),
          numHashFunctions: newBloomFilter.numHashFunctions,
          size: newBloomFilter.size,
        ),
      );
    } else {
      await BloomFilterProfile.db.insertRow(
        session,
        BloomFilterProfile(
          createdAt: now,
          bitArray: newBloomFilter.serialize(),
          numHashFunctions: newBloomFilter.numHashFunctions,
          size: newBloomFilter.size,
        ),
      );
    }
  }

  Future<BloomFilterPrehash> loadBloomFilter(
    Session session,
    bool isEventReport,
  ) async {
    final BloomFilterPrehash loadedBloom;
    if (isEventReport) {
      final bloomFilterEventDb = await BloomFilterEvent.db.findFirstRow(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
      if (bloomFilterEventDb != null) {
        loadedBloom = BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
          numHashFunctions: bloomFilterEventDb.numHashFunctions,
          byteArray: base64Decode(bloomFilterEventDb.bitArray),
          size: bloomFilterEventDb.size,
        );
      } else {
        loadedBloom = createEmtyBloom();
      }
    } else {
      final bloomFilterProfileDb = await BloomFilterProfile.db.findFirstRow(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );

      if (bloomFilterProfileDb != null) {
        loadedBloom = BloomFilterPrehash.fromNumHashFunctionsAndByteArray(
          numHashFunctions: bloomFilterProfileDb.numHashFunctions,
          byteArray: base64Decode(bloomFilterProfileDb.bitArray),
          size: bloomFilterProfileDb.size,
        );
      } else {
        loadedBloom = createEmtyBloom();
      }
    }

    return loadedBloom;
  }

  BloomFilterPrehash createEmtyBloom() {
    return BloomFilterPrehash(
      falsePositiveProbability: _bloomFalsePositiveProbability,
      numItems: _bloomNumItems,
    );
  }
}
