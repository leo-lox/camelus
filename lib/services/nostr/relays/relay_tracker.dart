import 'dart:developer';

import 'package:camelus/models/socket_control.dart';

enum RelayTrackerAdvType {
  kind03,
  nip05,
  tag,
}

class RelayTracker {
  /// pubkey,relayUrl :{, lastSuggestedKind3, lastSuggestedNip05, lastSuggestedBytag}
  Map<String, Map<String, dynamic>> tracker = {};

  RelayTracker() {}

  void clear() {
    tracker = {};
  }

  void analyzeNostrEvent(event, SocketControl socketControl) {
    // catch EOSE events etc.
    log("tracker:1 ${event[0]}");
    if (event[0] != "EVENT") {
      return;
    }

    Map eventMap = event[2];
    log("tracker:2 ${eventMap["tags"]}");
    // kind 3
    if (eventMap["kind"] == 3) {
      /* EXAMPLE
      "tags": [
          ["p", "91cf9..4e5ca", "wss://alicerelay.com/", "alice"],
          ["p", "14aeb..8dad4", "wss://bobrelay.com/nostr", "bob"],
          ["p", "612ae..e610f", "ws://carolrelay.com/ws", "carol"]
        ],
        */
      List<List> tags =
          (eventMap["tags"] as List).map((e) => e as List).toList();

      for (var tag in tags) {
        if (tag[0] == "p" && tag.length >= 3 && tag[2] != null) {
          trackRelay(tag[1], tag[2], RelayTrackerAdvType.kind03,
              eventMap["created_at"]);
        }
      }
    }

    // nip05
    if (eventMap["kind"] == 0) {
      //todo: move verification into own file with timestamp check ( only run every 24h )

    }
    // by tag
    if (eventMap["kind"] == 1) {
      /* EXAMPLE
      "tags": [
          ["e", <event-id>, <relay-url>, <marker>]
          ["p", <pubkey>, <relay-url>, <marker>]
        ],
        */

      //cast to List<List> to avoid type error
      List<List> tags =
          (eventMap["tags"] as List).map((e) => e as List).toList();

      for (var tag in tags) {
        if (tag[0] == "p" && tag.length >= 3 && tag[2] != null) {
          trackRelay(
              tag[1], tag[2], RelayTrackerAdvType.tag, eventMap["created_at"]);
        }
      }
    }
  }

  /// get called when a event advertises a relay pubkey connection
  /// timestamp can be a string or int
  void trackRelay(String personPubkey, String relayUrl, RelayTrackerAdvType nip,
      dynamic timestamp) {
    if (timestamp.runtimeType == String) {
      timestamp = int.parse(timestamp);
    }

    if (personPubkey.isEmpty || relayUrl.isEmpty) {
      return;
    }

    _populateTracker(personPubkey, relayUrl);
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
    log("tracker: $tracker");
  }

  _populateTracker(String personPubkey, String relayUrl) {
    if (tracker[personPubkey] == null) {
      tracker[personPubkey] = {};
    }
    if (tracker[personPubkey]![relayUrl] == null) {
      tracker[personPubkey]![relayUrl] = {};
    }
  }
}
