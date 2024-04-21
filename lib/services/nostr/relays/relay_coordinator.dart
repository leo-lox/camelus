import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:isolate';

import 'package:camelus/data_layer/db/entities/db_note.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/isolates/db_worker.dart';
import 'package:camelus/data_layer/models/nostr_note.dart';
import 'package:camelus/data_layer/models/nostr_request_event.dart';
import 'package:camelus/data_layer/models/nostr_request_query.dart';
import 'package:camelus/data_layer/models/nostr_tag.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/services/nostr/metadata/block_mute_service.dart';
import 'package:camelus/services/nostr/metadata/nip_65.dart';
import 'package:camelus/services/nostr/relays/my_relay.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';
import 'package:camelus/services/nostr/relays/relay_subscription_holder.dart';
import 'package:camelus/services/nostr/relays/relays_picker.dart';
import 'package:isar/isar.dart';

class RelayCoordinator {
  final _maxTmpRelayCount = 5; // move magic number to settings
  final Future<Isar> dbFuture;

  final Future<KeyPairWrapper> keyPairFuture;

  late Isar _db;
  late KeyPair _keyPair;
  late SendPort _dbWorkerSendPort;

  final List<RelaySubscriptionHolder> _activeSubscriptions = [];
  final List<MyRelay> _relays = [];
  final List<String> _currentlyConnectingRelays = [];
  List<RelayAssignment> _gossipRelayAssignments = [];

  final Completer _ready = Completer();

  final List<NostrTag> _ownContacts = [];
  int _fetchLatestContactListAt = 0;

  List<MyRelay> get relays => _relays;
  Stream<List<MyRelay>> get relaysStream => _relaysStreamController.stream;
  final StreamController<List<MyRelay>> _relaysStreamController =
      StreamController<List<MyRelay>>.broadcast();

  Future<BlockMuteService> blockMuteServiceFuture;
  late BlockMuteService _blockMuteService;

  RelayCoordinator({
    required this.dbFuture,
    required this.keyPairFuture,
    required this.blockMuteServiceFuture,
  }) {
    _init();
  }

  _init() async {
    _dbWorkerSendPort = await initIsolate();

    _db = await dbFuture;
    _keyPair = (await keyPairFuture).keyPair!;

    _blockMuteService = await blockMuteServiceFuture;

    await _initStreamOwnContacts(_keyPair.publicKey);

    await _initConnectSequence();

    _ready.complete();

    _setupOwnPermanentSubscription(pubkey: _keyPair.publicKey);
  }

  // following provider cant be used because circular dependency
  Future _initStreamOwnContacts(String myPubkey) async {
    Query<DbNote> kindPubkeyQuery = _db.dbNotes
        .filter()
        .pubkeyEqualTo(myPubkey)
        .and()
        .kindEqualTo(3)
        .build();

    kindPubkeyQuery.watch(fireImmediately: true).listen((dbList) {
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

    //! disabled gossip for now
    // for (var relay in selectedGossipRelays.entries) {
    //   connectFutures.add(
    //     _connectToRelay(
    //       relayUrl: relay.key,
    //       read: relay.value['read'] ?? true,
    //       write: relay.value['write'] ?? true,
    //       persistance: RelayPersistance.gossip,
    //     ),
    //   );
    // }

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
      log("WARN: already have subscription for this request");
      //return;
    }

    var possiblePubkeys = request.getAllPossiblePubkeys;
    if (possiblePubkeys.isNotEmpty) {
      return _optimizedPubkeyRequest(
        request: request,
        subscription: subscription,
        timeout: timeout,
      );
    }

    var allReadRelays = _relays.where((element) => element.read).toList();

    if (allReadRelays.isEmpty) {
      throw Exception("no read relays");
    }

    List<Future<String>> allRelayRequests = [];
    for (var relay in allReadRelays) {
      var future = relay.request(request);
      allRelayRequests.add(future);
      subscription.addRelay(relay);
      log("sending unoptimized request to ${relay.relayUrl} -- ${request.subscriptionId}");
    }
    var combinedFuture = Future.wait(allRelayRequests).timeout(
      timeout,
      onTimeout: () {
        return [];
      },
    );
    return combinedFuture;
  }

  Future _optimizedPubkeyRequest({
    required NostrRequestQuery request,
    required RelaySubscriptionHolder subscription,
    required Duration timeout,
  }) async {
    var connectedRelays =
        _relays.where((element) => element.connected).toList();
    var connectedRelayUrls = connectedRelays.map((e) => e.relayUrl).toList();

    var nip65Helper = Nip65(_db);

    // find minimal relay set
    var minimalRelaySet = await nip65Helper.calcMinimalRelaySet(
      pubkeys: request.getAllPossiblePubkeys,
      preferConnectedRelays: connectedRelayUrls,
    );

    // split among found pubkey relay assignments
    var foundSplitAssignmentRequest = Nip65.splitUpRequests(
      request: request,
      assignments: minimalRelaySet.relayAssignments,
    );

    // craft relay assignment for missing pubkeys
    List<String> combindedRelayUrls = [
      ...connectedRelayUrls,
      ...minimalRelaySet.relayAssignments.map((e) => e.relayUrl)
    ];
    // remove duplicates
    combindedRelayUrls = combindedRelayUrls.toSet().toList();

    List<RelayAssignment> missingAssignments = [];
    if (minimalRelaySet.missingWithNoRelay.isNotEmpty) {
      for (var relayUrl in combindedRelayUrls) {
        missingAssignments.add(
          RelayAssignment(
            relayUrl: relayUrl,
            pubkeys: minimalRelaySet.missingWithNoRelay,
          ),
        );
      }
    }

    var missingSplitAssignmentRequest = Nip65.splitUpRequests(
      request: request,
      assignments: missingAssignments,
    );

    // connect to relays that are not connected yet
    List<Future<MyRelay?>> autoRelayFuture = [];
    for (var splitRequest in foundSplitAssignmentRequest.entries) {
      if (connectedRelayUrls.contains(splitRequest.key)) {
        // already connected to this relay
        continue;
      }
      if (_currentlyConnectingRelays.contains(splitRequest.key)) {
        continue;
      }
      autoRelayFuture.add(_connectToRelay(
        relayUrl: splitRequest.key,
        read: true,
        write: false,
        persistance: RelayPersistance.auto,
      ));
    }
    var myNewAutoRelaysResult =
        await Future.wait(autoRelayFuture, eagerError: false);
    // remove nulls
    myNewAutoRelaysResult.removeWhere((element) => element == null);
    List<MyRelay> myNewAutoRelays =
        myNewAutoRelaysResult.map((e) => e as MyRelay).toList();

    var combindedRelays = [...myNewAutoRelays, ...connectedRelays];

    // send out requests
    List<Future<String>> allRelayRequests = [];

    for (var relay in combindedRelays) {
      if (foundSplitAssignmentRequest.containsKey(relay.relayUrl) &&
          missingSplitAssignmentRequest.containsKey(relay.relayUrl)) {
        var myFirstRequest = foundSplitAssignmentRequest[relay.relayUrl]!;
        var mySecondRequest = missingSplitAssignmentRequest[relay.relayUrl]!;
        var myCombinedRequest = myFirstRequest.mergeQuery(mySecondRequest);

        log("sending combined request to ${relay.relayUrl} for ${myCombinedRequest.body.authors} ${myCombinedRequest.subscriptionId}");

        var future = relay.request(myCombinedRequest);
        allRelayRequests.add(future);
        // to listen to EOSE response
        subscription.addRelay(relay);

        continue;
      }

      if (foundSplitAssignmentRequest.containsKey(relay.relayUrl)) {
        var myRequest = foundSplitAssignmentRequest[relay.relayUrl]!;
        log("sending targeted request to ${relay.relayUrl} for ${myRequest.body.authors} ${myRequest.subscriptionId}");

        var future = relay.request(myRequest);
        allRelayRequests.add(future);
        // to listen to EOSE response
        subscription.addRelay(relay);
        //continue; // todo combine with missing
      }

      if (missingSplitAssignmentRequest.containsKey(relay.relayUrl)) {
        var myRequest = missingSplitAssignmentRequest[relay.relayUrl]!;
        log("sending missing request to ${relay.relayUrl} for ${myRequest.body.authors} ${myRequest.subscriptionId}");

        var future = relay.request(myRequest);
        allRelayRequests.add(future);
        // to listen to EOSE response
        subscription.addRelay(relay);
      }
    }

    var combinedFuture = Future.wait(allRelayRequests).timeout(
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
    List<Future<MyRelay?>> futures = [];
    for (var relay in relaysToConnect) {
      futures.add(_connectToRelay(
        relayUrl: relay,
        read: true,
        write: false,
        persistance: RelayPersistance.tmp,
      ));
    }
    var myTmpRelaysResult = await Future.wait(futures);
    myTmpRelaysResult.removeWhere((element) => element == null);
    List<MyRelay> myTmpRelays =
        myTmpRelaysResult.map((e) => e as MyRelay).toList();

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

  Future<List<String>> write({
    required NostrRequestEvent request,
    Duration timeout = const Duration(seconds: 10),
    List<String> exactRelays = const [],
  }) async {
    List<MyRelay> allWriteRelays =
        _relays.where((element) => element.write).toList();

    List<MyRelay> connectedRelaysThatMatch = [];

    if (exactRelays.isNotEmpty) {
      connectedRelaysThatMatch = _relays
          .where((element) => exactRelays.contains(element.relayUrl))
          .toList();
    }

    List<String> toConnectRelays = exactRelays
        .where((element) =>
            !connectedRelaysThatMatch
                .any((connected) => connected.relayUrl == element) &&
            allWriteRelays.any((all) => all.relayUrl == element))
        .toList();

    List<Future<MyRelay?>> futures = [];
    for (var relay in toConnectRelays) {
      futures.add(_connectToRelay(
        relayUrl: relay,
        read: false,
        write: true,
        persistance: RelayPersistance.tmp,
      ));
    }
    // remove nulls
    var myTmpRelaysResult = await Future.wait(futures);
    myTmpRelaysResult.removeWhere((element) => element == null);
    List<MyRelay> myTmpRelays =
        myTmpRelaysResult.map((e) => e as MyRelay).toList();

    List<MyRelay> combinedRelays = [];
    if (exactRelays.isEmpty) {
      combinedRelays = [...allWriteRelays];
    } else {
      combinedRelays = [...connectedRelaysThatMatch, ...myTmpRelays];
    }

    List<Future<String>> relayRequests = [];
    // send request to combined relays
    for (var relay in combinedRelays) {
      var future = relay.request(request);
      relayRequests.add(future);
    }

    var combinedFuture = Future.wait(relayRequests).timeout(
      timeout,
      onTimeout: () {
        return [];
      },
    );

    // disconnect write tmp relays
    for (var relay in myTmpRelays) {
      await relay.close();
    }

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
    Query<DbNote> kindPubkeyQuery =
        _db.dbNotes.filter().pubkeyEqualTo(pubkey).and().kindEqualTo(3).build();

    var kind3 = await kindPubkeyQuery.findAll();

    if (kind3.isEmpty) {
      throw Exception("No relays found for this user");
    }
    NostrNote latest = kind3.first.toNostrNote();
    var rawJson = jsonDecode(latest.content);

    // cast to Map<String, Map<String, bool>>
    var toCast = Map<String, Map<dynamic, dynamic>>.from(rawJson);

    toCast.map((key, value) {
      var casted = Map<String, bool>.from(value);
      toCast[key] = casted;
      return MapEntry(key, casted);
    });
    var relays = Map<String, Map<String, bool>>.from(toCast);

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

  Future<MyRelay?> _connectToRelay({
    required String relayUrl,
    required bool read,
    required bool write,
    required RelayPersistance persistance,
  }) async {
    _currentlyConnectingRelays.add(relayUrl);

    var relay = MyRelay(
      database: _db,
      relayUrl: relayUrl,
      read: read,
      write: write,
      persistance: persistance,
      blockMuteService: _blockMuteService,
      dbWorkerSendPort: _dbWorkerSendPort,
    );
    try {
      await relay.connect();
    } catch (e) {
      _currentlyConnectingRelays.remove(relayUrl);
      log("Failed to connect to relay: $relayUrl error: $e");
      return null;
    }

    _relays.add(relay);
    _relaysStreamController.add(_relays);
    _currentlyConnectingRelays.remove(relayUrl);
    return relay;
  }

  Future<List<RelayAssignment>> _getOptimalRelays(List<String> pubkeys) async {
    var relaysPicker = RelaysPicker(db: _db);
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
        0, // metadata
        1, // posts
        3, // contacts
        10000, // mute list
        10002, //nip 65
      ],
      limit: 5,
    );
    var myRequest = NostrRequestQuery(subscriptionId: "self", body: myBody);
    request(request: myRequest);
  }
}
