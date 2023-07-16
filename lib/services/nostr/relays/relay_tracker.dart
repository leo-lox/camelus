import 'dart:convert';

import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/services/nostr/metadata/metadata_injector.dart';
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';
import 'package:cross_local_storage/cross_local_storage.dart';
import 'package:json_cache/json_cache.dart';

enum RelayTrackerAdvType {
  kind03,
  nip05,
  tag,
  lastFetched,
}

class RelayTracker {
  /// pubkey,relayUrl :{, lastSuggestedKind3, lastSuggestedNip05, lastSuggestedBytag}
  Map<String, Map<String, dynamic>> tracker = {};

  late Nip05 nip05service;
  late JsonCache jsonCache;

  RelayTracker() {
    nip05service = MetadataInjector().nip05;

    _initJsonCache();
  }

  void _initJsonCache() async {
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    jsonCache = JsonCacheCrossLocalStorage(prefs);
    _restoreFromCache();
  }

  void _restoreFromCache() async {
    var cache = await jsonCache.value('tracker');
    // cast to Map<String, Map<String, dynamic>>

    if (cache != null) {
      // cast to Map<String, Map<String, dynamic>>
      var cacheMap = Map.fromEntries(cache.entries.map(
          (entry) => MapEntry(entry.key, entry.value as Map<String, dynamic>)));

      tracker = cacheMap;
    }
  }

  void _updateCache() async {
    await jsonCache.refresh('tracker', tracker);
  }

  void clear() {
    tracker = {};
    _updateCache();
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

      Map<String, dynamic> result =
          await nip05service.checkNip05(nip05, pubkey);

      if (result.isEmpty) {
        return;
      }

      if (!result["valid"]) {
        return;
      }

      if (result["relays"] == null) {
        return;
      }

      List<String> resultRelays = List<String>.from(result["relays"]);

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
      RelayTrackerAdvType nip, dynamic timestamp) {
    var relayUrlsCleaned = <String>[];

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

    for (var relayUrl in relayUrlsCleaned) {
      _populateTracker(personPubkey, relayUrl);
    }

    for (var relayUrl in relayUrlsCleaned) {
      if (relayUrl.isEmpty) {
        continue;
      }
      if (personPubkey.isEmpty) {
        continue;
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
        case RelayTrackerAdvType.lastFetched:
          tracker[personPubkey]![relayUrl]!["lastFetched"] = timestamp;
          break;
      }
    }
    _updateCache();
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
