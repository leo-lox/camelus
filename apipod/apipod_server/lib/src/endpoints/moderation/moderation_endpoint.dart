import 'package:ndk/ndk.dart' hide LogLevel;
import 'package:serverpod/serverpod.dart';

import '../../config/service_config.dart';
import '../../generated/bloom_filter_data.dart';
import '../../generated/bloom_filter_events.dart';
import '../../generated/bloom_filter_profiles.dart';
import '../../generated/reports_incoming.dart';
import 'process_report.dart';

///    'size': <int>,
///    'numHashFunctions': <int>,
///    'bitArray': <string>,
class ModerationEndpoint extends Endpoint {
  static final cacheKeyProfiles = 'bloom-filter-profiles';
  static final cacheKeyEvents = 'bloom-filter-events';
  static final bloomFilterCacheLifetime = Duration(minutes: 10);

  Future<BloomFilterData?> getProfileBloomFilter(Session session) async {
    var bloomFilter =
        await session.caches.local.get<BloomFilterProfile>(cacheKeyProfiles);

    if (bloomFilter == null) {
      bloomFilter = await BloomFilterProfile.db.findFirstRow(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
      if (bloomFilter != null) {
        await session.caches.local.put(
          cacheKeyProfiles,
          bloomFilter,
          lifetime: bloomFilterCacheLifetime,
        );
      }
    }
    if (bloomFilter == null) {
      return null;
    }

    return BloomFilterData(
      size: bloomFilter.size,
      numHashFunctions: bloomFilter.numHashFunctions,
      bitArray: bloomFilter.bitArray,
      createdAt: bloomFilter.createdAt,
    );
  }

  Future<BloomFilterData?> getEventBloomFilter(Session session) async {
    var bloomFilter =
        await session.caches.local.get<BloomFilterEvent>(cacheKeyEvents);

    if (bloomFilter == null) {
      bloomFilter = await BloomFilterEvent.db.findFirstRow(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
      if (bloomFilter != null) {
        await session.caches.local.put(
          cacheKeyEvents,
          bloomFilter,
          lifetime: bloomFilterCacheLifetime,
        );
      }
    }
    if (bloomFilter == null) {
      return null;
    }

    return BloomFilterData(
      size: bloomFilter.size,
      numHashFunctions: bloomFilter.numHashFunctions,
      bitArray: bloomFilter.bitArray,
      createdAt: bloomFilter.createdAt,
    );
  }

  /// accepts a nostr report event \
  /// will be integrated into a relay in the future
  Future<String> report(
    Session session,
    Nip01Event reportEvent,
  ) async {
    final event = reportEvent;

    final isValidSig = await Bip340EventVerifier().verify(event);

    if (!isValidSig) {
      session.log("invalid sig", level: LogLevel.info);
      return "invalid sig";
    }

    session.log("report", level: LogLevel.info);

    DateTime now = DateTime.now();
    final isEventReport = event.getFirstTag('e') != null;

    if (ServiceConfig.trustedPubkeys.contains(event.pubKey)) {
      final process = ProcessReport();

      return process.processEvent(
        event: event,
        session: session,
        isEventReport: isEventReport,
      );
    }

    // save report in db
    await ReportsIncoming.db.insertRow(
      session,
      ReportsIncoming(
        createdAt: now,
        report: Nip01EventModel.fromEntity(event),
        author: event.pubKey,
        type: isEventReport ? "event" : "profile",
        processed: false,
      ),
    );

    return "ok";
  }
}
