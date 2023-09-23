import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camelus/db/entities/db_note.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/db/queries/db_user_metadata_queries.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:isar/isar.dart';

///
/// how metadata request works
///
/// batches of pubkeys in metadata request
/// request pool
/// mark no metadata available in cache do prevent double requests
///

class UserMetadata {
  //Map<String, dynamic> usersMetadata = {};
  List<DbUserMetadata> usersMetadata = [];
  //var metadataLastFetch = <String, int>{};

  final RelayCoordinator relays;
  final Future<Isar> dbFuture;
  late Isar _db;

  List<String> _metadataWaitingPool = [];
  late Timer _metadataWaitingPoolTimer;
  var _metadataWaitingPoolTimerRunning = false;
  Map<String, Completer<List<DbUserMetadata?>>> _metadataFutureHolder = {};

  final Completer _serviceRdy = Completer();

  late Stream<List<DbUserMetadata>> dbStream;

  UserMetadata({
    required this.relays,
    required this.dbFuture,
  }) {
    _init();
  }

  _setupDbMetadataListener() {
    DbUserMetadataQueries.getAllStream(_db).listen((event) {
      usersMetadata = event;
    });
  }

  _init() async {
    _db = await dbFuture;
    _restoreCache().then((_) => {_removeOldData()});
    _initDb();
    _setupDbMetadataListener();
    _setupDbLisener(_db);
    _serviceRdy.complete();
  }

  _initDb() {
    DbNoteQueries.kindStream(_db, kind: 0).listen((event) {
      List<NostrNote> notes = event.map((e) => e.toNostrNote()).toList();
      _receiveNostrEvents(notes);
    });
  }

  Future<void> _restoreCache() async {
    return;
  }

  _removeOldData() {
    // 2 weeks //todo move magic number to settings
    int timeOffset = 60 * 60 * 24 * 2;
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var timeBarrier = now - timeOffset;

    _db.writeTxn(() async {
      _db.dbUserMetadatas.filter().last_fetchLessThan(timeBarrier).deleteAll();
      _db.dbNotes
          .filter()
          .kindEqualTo(0)
          .last_fetchLessThan(timeBarrier)
          .deleteAll();
    });
  }

  _setupDbLisener(Isar db) {
    dbStream = DbUserMetadataQueries.getAllStream(_db).asBroadcastStream();
  }

  DbUserMetadata? getMetadataByPubkeyInitial(String pubkey) {
    DbUserMetadata? result;
    try {
      result = usersMetadata.where((element) => element.pubkey == pubkey)
          as DbUserMetadata?;
    } catch (e) {
      //
    }

    return result;
  }

  Stream<DbUserMetadata?> getMetadataByPubkeyStream(String pubkey) {
    return _getMetadataByPubkeyStream(pubkey).asBroadcastStream();
  }

  Stream<DbUserMetadata?> _getMetadataByPubkeyStream(String pubkey) async* {
    await _serviceRdy.future;
    try {
      final result =
          usersMetadata.firstWhere((element) => element.pubkey == pubkey);

      yield result;
    } catch (e) {
      // fetch from nostr network
      _getMetadataByPubkeyFromNetwork(pubkey);
    }

    // setup listener
    await for (var i in dbStream) {
      if (i.any((element) => element.pubkey == pubkey)) {
        final result = i.firstWhere((element) => element.pubkey == pubkey);

        yield result;
        return; // output only once
      }
    }
  }

  Future _getMetadataByPubkeyFromNetwork(String pubkey) async {
    await _serviceRdy.future;
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (pubkey.isEmpty) {
      return Future(() => null);
    }

    // check if pubkey is already in waiting pool
    if (!(_metadataWaitingPool.contains(pubkey))) {
      _metadataWaitingPool.add(pubkey);
    }

    Completer<List<DbUserMetadata?>> metadataResult = Completer();

    // if pool is full submit request
    if (_metadataWaitingPool.length >= 50) {
      _metadataWaitingPoolTimer.cancel();
      _metadataWaitingPoolTimerRunning = false;

      // submit request
      metadataResult.complete(_prepareMetadataRequest());
    } else if (!_metadataWaitingPoolTimerRunning) {
      _metadataWaitingPoolTimerRunning = true;
      _metadataWaitingPoolTimer = Timer(const Duration(milliseconds: 200), () {
        _metadataWaitingPoolTimerRunning = false;
        _metadataWaitingPoolTimer.cancel();

        // submit request
        metadataResult.complete(_prepareMetadataRequest());
      });
    } else {
      // cancel previous timer
      _metadataWaitingPoolTimer.cancel();
      // start timer again
      _metadataWaitingPoolTimerRunning = true;
      _metadataWaitingPoolTimer = Timer(const Duration(milliseconds: 200), () {
        _metadataWaitingPoolTimerRunning = false;

        // submit request
        metadataResult.complete(_prepareMetadataRequest());
      });
    }

    // don't add to future holder if already in there (double requests from future builder)
    if (_metadataFutureHolder[pubkey] == null) {
      _metadataFutureHolder[pubkey] = Completer<List<DbUserMetadata?>>();
    }

    metadataResult.future.then((value) => {
          for (var key in _metadataFutureHolder.keys)
            {
              _metadataFutureHolder[key]!.complete(value)
              // remove
            },
          _metadataFutureHolder = {},
        });

    //return await DbUserMetadataQueries.pubkeyLastFuture(_db, pubkey: pubkey);

    // return metadataResult.future.then((value) => value
    //     .where((element) => element != null && element.pubkey == pubkey)
    //     .firstOrNull);

    var myResult = _metadataFutureHolder[pubkey]!.future;

    return myResult.then((value) {
      DbUserMetadata? result;
      for (var element in value) {
        if (element != null && element.pubkey == pubkey) {
          result = element;
          continue;
        }
      }
      return result;
    });

    //return _metadataFutureHolder[pubkey]!.future;
  }

  /// prepare metadata request
  Future<List<DbUserMetadata>> _prepareMetadataRequest() async {
    // gets notified when first or last (on no data) request is received

    var requestId = "metadata-${Helpers().getRandomString(4)}";

    List<String> poolCopy = [..._metadataWaitingPool];

    await _requestMetadata(poolCopy, requestId);

    // free pool
    _metadataWaitingPool = [];

    // wait 300ms for the contacts to be received
    await Future.delayed(const Duration(milliseconds: 500));
    return usersMetadata;
  }

  Future _requestMetadata(List<String> users, requestId) async {
    var body = NostrRequestQueryBody(
      authors: users,
      kinds: [0, 10002], // + nip 65
      limit: users.length,
    );
    var request = NostrRequestQuery(subscriptionId: requestId, body: body);
    await relays.request(request: request, timeout: const Duration(seconds: 2));
    relays.closeSubscription(requestId);
    return;
  }

  _receiveNostrEvents(List<NostrNote> notes) {
    for (var note in notes) {
      int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      try {
        var json = jsonDecode(note.content);

        var newMetadata = DbUserMetadata(
          nostr_id: note.id,
          pubkey: note.pubkey,
          last_fetch: now,
          picture: json['picture'],
          banner: json['banner'],
          name: json['name'],
          nip05: json['nip05'],
          about: json['about'],
          website: json['website'],
          lud06: json['lud06'],
          lud16: json['lud16'],
        );

        _db.writeTxn(() async {
          var latestMeta = await DbUserMetadataQueries.pubkeyLastFuture(_db,
              pubkey: newMetadata.pubkey);
          // dont update if latest metadata is newer
          if (latestMeta != null &&
              latestMeta.last_fetch > newMetadata.last_fetch) {
            return;
          }

          _db.dbUserMetadatas.putByPubkey(newMetadata);
        });
      } catch (e) {
        return;
      }
    }
  }
}
