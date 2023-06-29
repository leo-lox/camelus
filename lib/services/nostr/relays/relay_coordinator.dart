import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/database.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/relays/my_relay.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';
import 'package:camelus/services/nostr/relays/relay_subscription_holder.dart';
import 'package:camelus/services/nostr/relays/relays_picker.dart';

class RelayCoordinator {
  final _maxTmpRelayCount = 5; // move magic number to settings
  final Future<AppDatabase> dbFuture;
  final Future<KeyPairWrapper> keyPairFuture;

  late AppDatabase _db;
  late KeyPair _keyPair;

  List<RelaySubscriptionHolder> _activeSubscriptions = [];
  List<MyRelay> _relays = [];
  List<RelayAssignment> _gossipRelayAssignments = [];

  final Completer _ready = Completer();

  final List<NostrTag> _ownContacts = [];
  int _fetchLatestContactListAt = 0;

  RelayCoordinator({
    required this.dbFuture,
    required this.keyPairFuture,
  }) {
    _init();
  }

  _init() async {
    _db = await dbFuture;
    _keyPair = (await keyPairFuture).keyPair!;

    await _initStreamOwnContacts(_keyPair.publicKey);

    await _initConnectSequence();

    _ready.complete();

    _setupOwnPermanentSubscription(pubkey: _keyPair.publicKey);
  }

  // following provider cant be used because circular dependency
  Future _initStreamOwnContacts(String myPubkey) async {
    _db.noteDao.findPubkeyNotesByKindStream([myPubkey], 3).listen((dbList) {
      if (dbList.isEmpty) {
        //_contactsController.add([]);
        return;
      }

      var kind3 = dbList.first.toNostrNote();
      // got something older than latest event
      if (_fetchLatestContactListAt != 0 &&
          kind3.created_at <= _fetchLatestContactListAt) {
        return;
      }

      _fetchLatestContactListAt = kind3.created_at;

      var newContacts = kind3.getTagPubkeys;

      _ownContacts.clear();
      _ownContacts.addAll(newContacts);
    });
  }

  Future<void> _initConnectSequence() async {
    var selectedManualRelays = await _findInitalManualRelays();

    List<Future> connectFutures = [];
    for (var relay in selectedManualRelays.entries) {
      connectFutures.add(
        _connectToRelay(
          relayUrl: relay.key,
          read: relay.value['read'] ?? true,
          write: relay.value['write'] ?? true,
          persistance: RelayPersistance.manual,
        ),
      );
    }

    List<String> followingPubkeys = _ownContacts.map((e) => e.value).toList();

    var selectedGossipRelays = await _findInitalGossipRelays(followingPubkeys);
    //remove potential duplicates
    selectedGossipRelays.removeWhere((key, value) =>
        selectedManualRelays.containsKey(key) ||
        _relays.any((element) => element.relayUrl == key));

    for (var relay in selectedGossipRelays.entries) {
      connectFutures.add(
        _connectToRelay(
          relayUrl: relay.key,
          read: relay.value['read'] ?? true,
          write: relay.value['write'] ?? true,
          persistance: RelayPersistance.gossip,
        ),
      );
    }

    await Future.any(connectFutures);
    // wait additional 2 seconds for other relays to connect
    await Future.delayed(const Duration(seconds: 2));
    return;
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

  Future request({
    required NostrRequestQuery request,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    await _ready.future; // wait to be connected to at least one relay

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

    List<Future<String>> relayRequests = [];
    for (var relay in _relays) {
      if (splitRequest.containsKey(relay.relayUrl)) {
        var relayRequest = splitRequest[relay.relayUrl];
        var future = relay.request(relayRequest!);

        relayRequests.add(future);
        // to listen to EOSE response
        subscription.addRelay(relay);
      }
    }

    var combinedFuture = Future.wait(relayRequests).timeout(
      timeout,
      onTimeout: () {
        return [];
      },
    );
    return combinedFuture;
  }

  Future requestFromRelays({
    required NostrRequestQuery request,
    required List<String> relayCandidates,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    var subscription = _checkForAlreadyActiveSubscription(request);

    if (subscription == null) {
      // create new subscription
      subscription = RelaySubscriptionHolder(request: request);
      _activeSubscriptions.add(subscription);
    } else {
      log("already have subscription for this request");
      return;
    }

    var allReadRelays = _relays.where((element) => element.read).toList();

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

    List<Future<String>> relayRequests = [];
    // send request to combined relays
    for (var relay in combinedRelays) {
      var future = relay.request(request);
      relayRequests.add(future);
      // to listen to EOSE response
      subscription.addRelay(relay);
    }

    var combinedFuture = Future.wait(relayRequests).timeout(
      timeout,
      onTimeout: () {
        return [];
      },
    );
    return combinedFuture;
  }

  RelaySubscriptionHolder? _checkForAlreadyActiveSubscription(
      NostrRequestQuery request) {
    // check if we have a subscription for this request
    RelaySubscriptionHolder? subscription;
    for (var element in _activeSubscriptions) {
      if (element.subscriptionId == request.subscriptionId) {
        subscription = element;
        break;
      }
    }
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

    var readRelays = _relays.where((element) => element.read).toList();

    // add remaining pubkeys to new request for each relay  GENERAL
    for (var relay in readRelays) {
      var relayUrl = relay.relayUrl;

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
      log("relay-assignment: ${relay.relayUrl}, pubkey: ${relay.pubkeys.length}");
    }
    return foundRelays;
  }

  // used to keep in sync
  void _setupOwnPermanentSubscription({required String pubkey}) {
    var myBody = NostrRequestQueryBody(
      authors: [pubkey],
      kinds: [
        0,
        1,
        3,
      ],
      limit: 5,
    );
    var myRequest = NostrRequestQuery(subscriptionId: "self", body: myBody);
    request(request: myRequest);
  }
}
