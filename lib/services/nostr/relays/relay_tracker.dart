enum RelayTrackerAdvType {
  kind03,
  nip05,
  tag,
}

class RelayTracker {
  /// pubkey,relayUrl :{, lastSuggestedKind3, lastSuggestedNip05, lastSuggestedBytag}
  Map<String, Map<String, dynamic>> tracker = {};

  RelayTracker() {}

  /// get called when a event advertises a relay pubkey connection
  void trackRelay(String personPubkey, String relayUrl, RelayTrackerAdvType nip,
      int timestamp) {
    if (tracker[personPubkey] == null) {
      tracker[personPubkey] = {};
    }
    if (tracker[personPubkey]![relayUrl] == null) {
      tracker[personPubkey]![relayUrl] = {
        "relayUrl": relayUrl,
      };
    }

    switch (nip) {
      case RelayTrackerAdvType.kind03:
        tracker[personPubkey]![relayUrl]!["lastSuggestedKind3"] = timestamp;
        break;
      case RelayTrackerAdvType.nip05:
        tracker[personPubkey]![relayUrl]!["lastSuggestedNip05"] = timestamp;
        break;
      case RelayTrackerAdvType.tag:
        tracker[personPubkey]![relayUrl]!["lastSuggestedBytag"] = timestamp;
        break;
    }
  }
}
