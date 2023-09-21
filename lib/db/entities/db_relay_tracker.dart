import 'package:isar/isar.dart';

part 'db_relay_tracker.g.dart';

@collection
class DbRelayTracker {
  Id id = Isar.autoIncrement;

  @Index(unique: true, type: IndexType.value, replace: true)
  String pubkey;

  List<DbRelayTrackerRelay> relays;

  DbRelayTracker({
    required this.pubkey,
    this.relays = const [],
  });
}

@embedded
class DbRelayTrackerRelay {
  String? relayUrl;

  int? lastSuggestedKind3;
  int? lastSuggestedNip05;
  int? lastSuggestedTag;
  int? lastFetched;
  DbRelayTrackerRelay({
    this.relayUrl,
    this.lastSuggestedKind3,
    this.lastSuggestedNip05,
    this.lastSuggestedTag,
  });
}
