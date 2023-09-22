import 'dart:convert';

import 'package:camelus/db/entities/db_nip05.dart';
import 'package:camelus/db/entities/db_relay_tracker.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';
import 'package:isar/isar.dart';

enum RelayTrackerAdvType {
  kind03,
  nip05,
  tag,
  lastFetched,
}

class RelayTracker {
  /// pubkey,relayUrl :{, lastSuggestedKind3, lastSuggestedNip05, lastSuggestedBytag}
  //Map<String, Map<String, dynamic>> tracker = {};

  late Nip05 nip05service;
  Isar db;

  RelayTracker({required this.db}) {
    nip05service = Nip05(db: db);
  }

  void clear() {
    db.dbRelayTrackers.clear();
  }

  Future<void> analyzeNostrEvent(NostrNote event, String socketUrl) async {
    // lastFetched
    var personPubkey = event.pubkey;
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var myRelayUrl = RelayAddressParser.parseAddress(socketUrl);
    trackRelays(
        personPubkey, [myRelayUrl], RelayTrackerAdvType.lastFetched, now);

    // kind 3
    if (event.kind == 3) {
      /* EXAMPLE
      "tags": [
          ["p", "91cf9..4e5ca", "wss://alicerelay.com/", "alice"],
          ["p", "14aeb..8dad4", "wss://bobrelay.com/nostr", "bob"],
          ["p", "612ae..e610f", "ws://carolrelay.com/ws", "carol"]
        ],
        */

      List<NostrTag> nostrTags = event.tags ?? [];

      for (var tag in nostrTags) {
        if (tag.type == "p" && tag.recommended_relay != null) {
          trackRelays(
            tag.value,
            [tag.recommended_relay!],
            RelayTrackerAdvType.kind03,
            event.created_at,
          );
        }
      }

      if (event.content == "") {
        return;
      }

      // own adv
      Map content = jsonDecode(event.content);
      List<String> writeRelays = [];
      String personPubkey = event.pubkey ?? "";

      if (personPubkey.isEmpty) {
        return;
      }

      // extract write relays
      for (var relay in content.entries) {
        if (relay.value["write"] == true) {
          writeRelays.add(relay.key);
        }
      }
      trackRelays(personPubkey, writeRelays, RelayTrackerAdvType.kind03,
          event.created_at);
    }

    // nip05
    if (event.kind == 0) {
      Map metadata = jsonDecode(event.content);
      String nip05 = metadata["nip05"] ?? "";
      String pubkey = event.pubkey;
      if (nip05.isEmpty || pubkey.isEmpty) {
        return;
      }

      DbNip05? result = await nip05service.checkNip05(nip05, pubkey);

      if (result == null) {
        return;
      }

      if (!result.valid) {
        return;
      }

      if (result.relays == null) {
        return;
      }

      List<String> resultRelays = List<String>.from(result.relays!);

      trackRelays(
          pubkey, resultRelays, RelayTrackerAdvType.nip05, event.created_at);
    }
    // by tag
    if (event.kind == 1) {
      /* EXAMPLE
      "tags": [
          ["e", <event-id>, <relay-url>, <marker>]
          ["p", <pubkey>, <relay-url>, <marker>]
        ],
        */

      List<NostrTag> nostrTags = event.tags ?? [];

      for (var tag in nostrTags) {
        if (tag.type == "p" && tag.recommended_relay != null) {
          trackRelays(tag.value, [tag.recommended_relay!],
              RelayTrackerAdvType.tag, event.created_at);
        }
      }
    }
  }

  /// get called when a event advertises a relay pubkey connection
  /// timestamp can be a string or int
  void trackRelays(String personPubkey, List<String> relayUrls,
      RelayTrackerAdvType nip, dynamic timestamp) async {
    var relayUrlsCleaned = <String>[];

    var oldObj = await db.dbRelayTrackers.getByPubkey(personPubkey);

    for (var relay in relayUrls) {
      try {
        var cleaned = RelayAddressParser.parseAddress(relay);
        relayUrlsCleaned.add(cleaned);
      } catch (e) {
        continue;
      }
    }

    if (timestamp.runtimeType == String) {
      timestamp = int.parse(timestamp);
    }

    if (personPubkey.isEmpty || relayUrlsCleaned.isEmpty) {
      return;
    }

    List<DbRelayTrackerRelay> trackedRelays = [];

    for (var relayUrl in relayUrlsCleaned) {
      if (relayUrl.isEmpty) {
        continue;
      }
      if (personPubkey.isEmpty) {
        continue;
      }

      var relay = DbRelayTrackerRelay(
        relayUrl: relayUrl,
      );

      if (oldObj != null &&
          oldObj.relays.any((element) => element.relayUrl == relayUrl)) {
        relay =
            oldObj.relays.firstWhere((element) => element.relayUrl == relayUrl);
      }

      switch (nip) {
        case RelayTrackerAdvType.kind03:
          relay.lastSuggestedKind3 = timestamp;
          break;
        case RelayTrackerAdvType.nip05:
          relay.lastSuggestedNip05 = timestamp;
          break;
        case RelayTrackerAdvType.tag:
          relay.lastSuggestedTag = timestamp;
          break;
        case RelayTrackerAdvType.lastFetched:
          relay.lastFetched = timestamp;
          break;
      }
      trackedRelays.add(relay);
    }

    var finalObj = DbRelayTracker(pubkey: personPubkey, relays: trackedRelays);

    await db.writeTxn(() async {
      db.dbRelayTrackers.putByPubkey(finalObj);
    });
  }
}
