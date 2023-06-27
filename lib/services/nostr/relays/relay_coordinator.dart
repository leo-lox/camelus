import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/metadata/following_pubkeys.dart';
import 'package:camelus/services/nostr/relays/my_relay.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';
import 'package:camelus/services/nostr/relays/relay_subscription_holder.dart';
import 'package:camelus/services/nostr/relays/relays_picker.dart';

class RelayCoordinator {
  final _maxTmpRelayCount = 5; // move magic number to settings
  final Future<AppDatabase> dbFuture;
  final Future<KeyPairWrapper> keyPairFuture;
  final Future<FollowingPubkeys> followingFuture;
  late AppDatabase _db;
  late KeyPair _keyPair;
  late FollowingPubkeys _following;

  List<RelaySubscriptionHolder> _activeSubscriptions = [];
  List<MyRelay> _relays = [];
  List<RelayAssignment> _gossipRelayAssignments = [];

  RelayCoordinator(
      {required this.dbFuture,
      required this.keyPairFuture,
      required this.followingFuture}) {
    _init();
  }

  _init() async {
    _db = await dbFuture;
    _keyPair = (await keyPairFuture).keyPair!;
    _following = await followingFuture;
    await _following.servicesReady;

    _initConnectSequence();
  }

  _initConnectSequence() async {
    var selectedManualRelays = await _findInitalManualRelays();

    for (var relay in selectedManualRelays.entries) {
      _connectToRelay(
        relayUrl: relay.key,
        read: relay.value['read'] ?? true,
        write: relay.value['write'] ?? true,
        persistance: RelayPersistance.manual,
      );
    }

    List<String> followingPubkeys =
        _following.ownContacts.map((e) => e.value).toList();

    var selectedGossipRelays = await _findInitalGossipRelays(followingPubkeys);
    //remove potential duplicates
    selectedGossipRelays.removeWhere((key, value) =>
        selectedManualRelays.containsKey(key) ||
        _relays.any((element) => element.relayUrl == key));

    for (var relay in selectedGossipRelays.entries) {
      _connectToRelay(
        relayUrl: relay.key,
        read: relay.value['read'] ?? true,
        write: relay.value['write'] ?? true,
        persistance: RelayPersistance.gossip,
      );
    }
  }

  Future<Map<String, Map<String, bool>>> _findInitalManualRelays() async {
    Map<String, Map<String, bool>> selectedRelays;

    //replace from api call for best relays in region
    final Map<String, Map<String, bool>> initRelays = {
      "wss://nostr.bitcoiner.social": {
        "write": true,
        "read": true,
      },
      "wss://nostr.zebedee.cloud": {
        "write": true,
        "read": true,
      },
      "wss://nos.lol": {"write": true, "read": true},
      "wss://relay.damus.io": {"write": true, "read": true},
    };

    // manual relays
    try {
      selectedRelays = await _getUserManualRelays(_keyPair.publicKey);
    } catch (e) {
      selectedRelays = initRelays;
    }

    return selectedRelays;
  }

  Future<Map<String, Map<String, bool>>> _findInitalGossipRelays(
      List<String> pubkeys) async {
    _gossipRelayAssignments = await _getOptimalRelays(pubkeys);

    var converted = Map.fromEntries(
        _gossipRelayAssignments.map((e) => MapEntry(e.relayUrl, {
              "write": false,
              "read": true,
            })));
    return converted;
  }

  request(NostrRequestQuery request) {
    var subscription = _checkForAlreadyActiveSubscription(request);

    if (subscription == null) {
      // create new subscription
      subscription = RelaySubscriptionHolder(request: request);
      _activeSubscriptions.add(subscription);
    } else {
      log("already have subscription for this request");
      return;
    }

    var splitRequest = _splitRequestByRelays(request);

    for (var relay in _relays) {
      if (splitRequest.containsKey(relay.relayUrl)) {
        var relayRequest = splitRequest[relay.relayUrl];
        relay.request(relayRequest!);
        // to listen to EOSE response
        subscription.addRelay(relay);
      }
    }
  }

  requestFromRelays(
      NostrRequestQuery request, List<String> relayCandidates) async {
    var subscription = _checkForAlreadyActiveSubscription(request);

    if (subscription == null) {
      // create new subscription
      subscription = RelaySubscriptionHolder(request: request);
      _activeSubscriptions.add(subscription);
    } else {
      log("already have subscription for this request");
      return;
    }

    // create list of alrady connected relays that match with the relayCandidates
    var connectedRelays = _relays
        .where((element) => relayCandidates.contains(element.relayUrl))
        .toList();

    var connectedTmpRelays = _relays
        .where((element) => element.persistance == RelayPersistance.tmp)
        .toList();
    int countOfTmpRelays = connectedTmpRelays.length;

    if (countOfTmpRelays >= _maxTmpRelayCount) {
      // disconnect oldest two tmp relays
      connectedTmpRelays.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (int i = 0; i < 2 - _maxTmpRelayCount; i++) {
        await connectedTmpRelays[i].close();
      }
    }

    // select two relays from relayCandidates that are not already connected
    var relaysToConnect = relayCandidates
        .where((element) =>
            !connectedRelays.any((connected) => connected.relayUrl == element))
        .take(2 - countOfTmpRelays)
        .toList();

    // connect to relays
    List<Future<MyRelay>> futures = [];
    for (var relay in relaysToConnect) {
      futures.add(_connectToRelay(
        relayUrl: relay,
        read: true,
        write: false,
        persistance: RelayPersistance.tmp,
      ));
    }
    var myTmpRelays = await Future.wait(futures);

    var combinedRelays = [...connectedRelays, ...myTmpRelays];

    // send request to combined relays
    for (var relay in combinedRelays) {
      relay.request(request);
      // to listen to EOSE response
      subscription.addRelay(relay);
    }
  }

  RelaySubscriptionHolder? _checkForAlreadyActiveSubscription(
      NostrRequestQuery request) {
    // check if we have a subscription for this request
    var subscription = (_activeSubscriptions as List<RelaySubscriptionHolder?>)
        .firstWhere(
            (element) => element?.subscriptionId == request.subscriptionId,
            orElse: () => null);
    return subscription;
  }

  addRelayToRequest(String requestId, String relayId) {
    return throw UnimplementedError();
  }

  // close the subscription but keeps the websocket open
  closeSubscription(String subscriptionId) {
    for (var subscription in _activeSubscriptions) {
      if (subscription.subscriptionId == subscriptionId) {
        subscription.close();
        _activeSubscriptions.remove(subscription);
        break;
      }
    }
  }

  Future<Map<String, Map<String, bool>>> _getUserManualRelays(
      String pubkey) async {
    var kind3 = await _db.noteDao.findPubkeyNotesByKind([pubkey], 3);
    if (kind3.isEmpty) {
      throw Exception("No relays found for this user");
    }
    NostrNote latest = kind3.first.toNostrNote();
    Map<String, Map<String, bool>> relays = jsonDecode(latest.content);

    // parse relayUrls
    for (var relayUrl in relays.keys) {
      try {
        relayUrl = RelayAddressParser.parseAddress(relayUrl);
      } catch (e) {
        // remove
        relays.remove(relayUrl);
        log("Invalid relay address: $relayUrl, removing from list");
      }
    }

    return relays;
  }

  Future<MyRelay> _connectToRelay({
    required String relayUrl,
    required bool read,
    required bool write,
    required RelayPersistance persistance,
  }) async {
    var relay = MyRelay(
        database: _db,
        relayUrl: relayUrl,
        read: read,
        write: write,
        persistance: persistance);
    await relay.connect();
    _relays.add(relay);
    return relay;
  }

  // return string is the relayUrl/relayId
  Map<String, NostrRequestQuery> _splitRequestByRelays(
      NostrRequestQuery request) {
    var requestBody = request.body;
    //Map<String, dynamic> requestBody = Map<String, dynamic>.from(request[2]);

    // don't do anything if there is no authors
    if (requestBody.authors == null) {
      for (MyRelay relay in _relays.where((element) => element.read)) {
        String relayUrl = relay.relayUrl;

        Map<String, NostrRequestQuery> requestsMap = {};

        requestsMap[relayUrl] = request;
        return requestsMap;
      }
    }
    List<String> pubkeys = requestBody.authors!;

    Map countMap = {};
    for (var pubkey in pubkeys) {
      countMap[pubkey] = 2; //todo: magic number move to settings
    }

    Map<String, List<String>> relayPubkeyMap = {};

    var assignments = _gossipRelayAssignments;

    // result should look like this
    // relayPubkeyMap = {
    //   "relay1": ["pubkey1", "pubkey2"],
    //   "relay2": ["pubkey3", "pubkey4"],
    // }
    // and with each iteration the countMap is reduced
    // countMap = {
    //   "pubkey1": 0,
    //   "pubkey2": 0,
    //   "pubkey3": 0,
    //   "pubkey4": 0,
    // }

    for (MyRelay relay in _relays.where((element) => element.read)) {
      var relayUrl = relay.relayUrl;

      for (var pubkey in pubkeys) {
        if (countMap[pubkey] == 0) {
          continue;
        }
        if (assignments
            .where((element) =>
                element.relayUrl == relayUrl &&
                element.pubkeys.contains(pubkey))
            .isNotEmpty) {
          if (relayPubkeyMap.containsKey(relayUrl)) {
            relayPubkeyMap[relayUrl]!.add(pubkey);
          } else {
            relayPubkeyMap[relayUrl] = [pubkey];
          }
          countMap[pubkey] = countMap[pubkey] - 1;
        }
      }
    }

    List<String> remainingPubkeys = List<String>.from(countMap.entries
        .where((element) => element.value > 0)
        .map((e) => e.key)
        .toList());

    Map<String, NostrRequestQuery> newRequests = {};
    // craft new request for each relay  SPECIFIC
    for (var relay in relayPubkeyMap.entries) {
      var relayUrl = relay.key;
      var pubkeys = relay.value;

      // deep copy request
      NostrRequestQuery newRequest = NostrRequestQuery(
          subscriptionId: request.subscriptionId, body: request.body);

      newRequest.body.authors = pubkeys;
      newRequests[relayUrl] = newRequest;
    }

    // add remaining pubkeys to new request for each relay  GENERAL
    for (String relayUrl
        in _relays.where((element) => element.read).map((e) => e.relayUrl)) {
      //var relayUrl = relay.key;

      if (newRequests.containsKey(relayUrl)) {
        var request = newRequests[relayUrl];

        request!.body.authors!.addAll(remainingPubkeys);
      } else {
        // deep copy request
        NostrRequestQuery newRequest = NostrRequestQuery(
            subscriptionId: request.subscriptionId, body: request.body);

        newRequest.body.authors = pubkeys;

        newRequests[relayUrl] = newRequest;
      }
    }

    return newRequests;
  }

  Future<List<RelayAssignment>> _getOptimalRelays(List<String> pubkeys) async {
    var relaysPicker = RelaysPicker();
    await relaysPicker.init(
        pubkeys: pubkeys,
        coverageCount: 2); //todo: move coverageCount to settings

    List<RelayAssignment> foundRelays = [];
    Map<String, int> excludedRelays = {};

    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    while (true) {
      try {
        var result = relaysPicker.pick(pubkeys);
        var assignment = relaysPicker.getRelayAssignment(result);
        if (assignment == null) {
          continue;
        }
        if (assignment.relayUrl.isEmpty) {
          continue;
        }
        foundRelays.add(assignment);

        // exclude already found relays
        excludedRelays[assignment.relayUrl] = now;

        relaysPicker.setExcludedRelays = excludedRelays;
      } catch (e) {
        log("catch: $e");
        break;
      }
    }
    for (var relay in foundRelays) {
      log("relay: ${relay.relayUrl}, pubkey: ${relay.pubkeys}");
    }
    log("found relays: $foundRelays");
    return foundRelays;
  }
}
