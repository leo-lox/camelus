import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/key_pair_provider.dart';

import 'package:camelus/services/nostr/metadata/metadata_injector.dart';
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:camelus/services/nostr/metadata/user_contacts.dart';
import 'package:camelus/services/nostr/relays/relay_tracker.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:camelus/services/nostr/relays/relays_ranking.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:hex/hex.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/bip340.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:json_cache/json_cache.dart';
import 'package:cross_local_storage/cross_local_storage.dart';

import 'package:camelus/models/socket_control.dart';

class NostrService {
  final Future<KeyPairWrapper> keyPairWrapper;

  late Future isNostrServiceConnected;

  static String ownPubkeySubscriptionId =
      "own-${Helpers().getRandomString(20)}";

  var userContactsObj = UserContacts();

  late JsonCache jsonCache;

  late Relays relays;
  late RelayTracker relayTracker;

  late KeyPair myKeys;

  late Nip05 nip05service;

  late RelaysRanking relaysRanking;

  // blocked users
  List<String> blockedUsers = [];

  Map<String, dynamic> get usersMetadata => {};
  Map<String, List<List<dynamic>>> get following => userContactsObj.following;

  NostrService({required this.keyPairWrapper}) {
    RelaysInjector relaysInjector = RelaysInjector();
    MetadataInjector metadataInjector = MetadataInjector();

    nip05service = metadataInjector.nip05;
    relays = relaysInjector.relays;
    relayTracker = relaysInjector.relayTracker;
    relaysRanking = relaysInjector.relaysRanking;
    isNostrServiceConnected = relays.isNostrServiceConnectedCompleter.future;

    relays.receiveEventStream.listen((e) {
      _receiveEvent(e["event"], e["socketControl"]);
    });

    _init();
  }

  _init() async {
    SystemChannels.lifecycle.setMessageHandler((msg) {
      log('SystemChannels> $msg');
      switch (msg) {
        case "AppLifecycleState.resumed":
          relays.checkRelaysForConnection();
          break;
        case "AppLifecycleState.inactive":
          break;
        case "AppLifecycleState.paused":
          break;
        case "AppLifecycleState.detached":
          relays.closeRelays();
          break;
      }
      // reconnect to relays
      return Future(() {
        return;
      });
    });

    await _loadKeyPair();

    // init streams

    // init json cache
    LocalStorageInterface prefs = await LocalStorage.getInstance();
    jsonCache = JsonCacheCrossLocalStorage(prefs);

    // restore blocked users
    var blockedUsersCache = (await jsonCache.value('blockedUsers'));
    if (blockedUsersCache != null) {
      // cast using for loop to avoid type error
      var list = blockedUsersCache["blockedUsers"];
      for (String u in list) {
        blockedUsers.add(u);
      }
    }
  }

  Future<void> _loadKeyPair() async {
    var wrapper = await keyPairWrapper;
    if (wrapper.keyPair == null) {
      return;
    }
    myKeys = wrapper.keyPair!;
  }

  finishedOnboarding() async {
    _loadKeyPair();

    await relays.connectToRelays(useDefault: true);

    // subscribe to own pubkey

    var data = [
      "REQ",
      ownPubkeySubscriptionId,
      {
        "authors": [myKeys.publicKey],
        "kinds": [0, 2, 3], // 0=> metadata, 2=> relays, 3=> contacts
      },
    ];

    var jsonString = json.encode(data);

    for (var relay in relays.connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
    }
  }

  /// used for debugging
  void clearCache() async {
    // clears everything including shared preferences! don't use this!
    //await jsonCache.clear();

    // clear only nostr related stuff
    await jsonCache.remove('userFeed');
    await jsonCache.remove('usersMetadata');
    await jsonCache.remove('following');

    // don't clear relays and blocked users
  }

  // clears everything, potentially dangerous
  void clearCacheReset() async {
    await jsonCache.clear();
  }

  _receiveEvent(event, SocketControl socketControl) async {
    log("this schould not happen");
  }

  writeEvent(String content, int kind, List tags) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    var calcId = [0, myKeys.publicKey, now, kind, tags, content];
    // serialize
    String calcIdJson = jsonEncode(calcId);

    // hash
    Digest id = sha256.convert(utf8.encode(calcIdJson));
    String idString = id.toString();

    // hex encode
    String idHex = HEX.encode(id.bytes);

    // sign
    String sig = Bip340().sign(idHex, myKeys.privateKey);

    var req = [
      "EVENT",
      {
        "id": idString,
        "pubkey": myKeys.publicKey,
        "created_at": now,
        "kind": kind,
        "tags": tags,
        "content": content,
        "sig": sig
      }
    ];

    log("write event: $req");

    var reqJson = jsonEncode(req);
    for (var relay in relays.connectedRelaysWrite.entries) {
      if (!(relay.value.socketIsRdy)) {
        log("socket not ready");
        continue;
      }
      relay.value.socket.add(reqJson);
    }
  }

  _howManyRequestsLeft(String requestId, SocketControl currentSocket,
      Map<String, SocketControl> pool) {
    int count = 0;
    for (var socket in pool.entries) {
      if (socket.value.requestInFlight.containsKey(requestId)) {
        if (socket.value.id == currentSocket.id) {
          continue;
        }
        count++;
      }
    }
    return count;
  }

  void requestAuthors(
      {required List<String> authors,
      required String requestId,
      int? since,
      int? until,
      int? limit}) {}

  void closeSubscription(String subId) {
    var data = [
      "CLOSE",
      subId,
    ];

    var jsonString = json.encode(data);
    for (var relay in relays.connectedRelaysRead.entries) {
      relay.value.socket.add(jsonString);
      relay.value.requestInFlight[subId] = true;
      //todo add stream
    }
  }

  /// get user metadata from cache and if not available request it from network
  Future<List<List<dynamic>>> getUserContacts(String pubkey,
      {bool force = false}) async {
    return [];
  }

  /// returns {nip05, valid, lastCheck, relayHint} exception
  Future<Map> checkNip05(String nip05, String pubkey) async {
    return await nip05service.checkNip05(nip05, pubkey);
  }

  Future<void> addToBlocklist(String pubkey) async {
    if (!blockedUsers.contains(pubkey)) {
      blockedUsers.add(pubkey);
      await jsonCache.refresh("blockedUsers", {"blockedUsers": blockedUsers});
    }

    return;
  }

  Future<void> removeFromBlocklist(String pubkey) async {
    if (blockedUsers.contains(pubkey)) {
      blockedUsers.remove(pubkey);
      await jsonCache.refresh("blockedUsers", {"blockedUsers": blockedUsers});
    }
    return;
  }

  Future<void> debug() async {
    List<String> userFollows = (await getUserContacts(myKeys.publicKey))
        .map<String>((e) => e[1])
        .toList();
    log("userFollows: $userFollows");
    log("debug");
    relays.getOptimalRelays(userFollows);
  }

  Future<void> pickAndReconnect() async {
    log("pickAndReconnect");
    var userFollows = (await getUserContacts(myKeys.publicKey))
        .map<String>((e) => e[1])
        .toList();
    log("userFollows: $userFollows");

    await relays.closeRelays();
    await relays.start(userFollows);
    return;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    throw UnimplementedError();
  }
}
