import 'package:camelus/services/nostr/relays/relay_tracker.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:developer' as developer;

class RelaysRanking {
  late RelayTracker relayTracker;

  RelaysRanking() {
    relayTracker = RelaysInjector().relayTracker;
  }

  Future<List<dynamic>> getBestRelays(String pubkeyHex, Direction dir) async {
    final rankedRelays = (() {
      //final maybeDb = "GLOBALS.db.blockingLock()";
      //final db = maybeDb.value;
      //final stmt = db.prepare(sql);
      //stmt.rawBindParameter(1, pubkeyHex);
      //final rows = stmt.rawQuery();

      var tracker = relayTracker.tracker;

      //
      //tracker to dbprs
      List<DbPersonRelay> dbprs = [];

      for (var entry in tracker[pubkeyHex]!.entries) {
        var d = DbPersonRelay(
            person: pubkeyHex,
            relay: entry.key,
            lastFetched: 0, //todo: implement lastFetched
            lastSuggestedKind3: entry.value["lastSuggestedKind3"] ?? 0,
            lastSuggestedNip05: entry.value["lastSuggestedNip05"] ?? 0,
            lastSuggestedBytag: entry.value["lastSuggestedBytag"] ?? 0,
            read: true,
            write: false,
            manuallyPairedRead: false,
            manuallyPairedWrite: false);
        dbprs.add(d);
      }

      // convert dbprs to List<Map<String, dynamic>>
      List<Map<String, dynamic>> dbprMap = [];
      for (var dbpr in dbprs) {
        dbprMap.add(dbpr.toMap());
      }

      switch (dir) {
        case Direction.write:
          return _writeRank(dbprMap);
        case Direction.read:
          return _readRank(dbprMap);
      }
      return [];
    });

    final rankedRelaysList = rankedRelays() as List<Map<String, dynamic>>;
    final numRelaysPerPerson = 2; //todo: move this to settings

    // If we can't get enough of them, extend with some of our relays
    // at whatever the lowest score of their last one was
    if (rankedRelaysList.length < (numRelaysPerPerson + 1)) {
      final howManyMore = (numRelaysPerPerson + 1) - rankedRelaysList.length;

      final lastScore = rankedRelaysList.isEmpty
          ? 20
          : rankedRelaysList.last.values.last; //rankedRelaysList.last.value2

      List<Tuple2<String, int>> myTuplesList = [
        Tuple2('a', 1),
        Tuple2('b', 2),
        Tuple2('c', 3),
      ];
      //final additional = myTuplesList
      //    .where((r) =>
      //        !rankedRelaysList.any((rel) => rel.values.first == r.key) &&
      //        ((dir == Direction.write && r.value.write) ||
      //            (dir == Direction.read && r.value.read)))
      //    .take(howManyMore)
      //    .map((r) => Tuple2(r.key.clone(), lastScore))
      //    .toList();
      //rankedRelaysList.addAll(additional);
    }

    //developer.log("rankedRelaysList: $rankedRelaysList", name: 'RelaysRanking');

    return rankedRelaysList;
  }

  List<Map<String, dynamic>> _writeRank(List<Map<String, dynamic>> dbprs) {
    // This is the ranking we are using. There might be reasons
    // for ranking differently.
    //   write (score=20)    [ they claim (to us) ]
    //   manually_paired_write (score=20)    [ we claim (to us) ]
    //   kind3 tag (score=5) [ we say ]
    //   nip05 (score=4)     [ they claim, unsigned ]
    //   fetched (score=3)   [ we found ]
    //   bytag (score=1)     [ someone else mentions ]

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var output = <Map<String, dynamic>>[];

    int scorefn(int when, int fadePeriod, int base) {
      var dur = now - when; // seconds since
      var periods = (dur / fadePeriod).floor() + 1; // minimum one period
      return base ~/ periods;
    }

    for (var dbpr in List<Map<String, dynamic>>.from(dbprs)) {
      var score = 0;

      // 'write' is an author-signed explicit claim of where they write
      if (dbpr['write'] ?? false || dbpr['manually_paired_write'] ?? false) {
        score += 20;
      }

      // kind3 is our memory of where we are following someone
      if (dbpr['last_suggested_kind3'] != null) {
        score += scorefn(
          dbpr['last_suggested_kind3'],
          60 * 60 * 24 * 30,
          7,
        );
      }

      // nip05 is an unsigned dns-based author claim of using this relay
      if (dbpr['last_suggested_nip05'] != null) {
        score += scorefn(
          dbpr['last_suggested_nip05'],
          60 * 60 * 24 * 15,
          4,
        );
      }

      // last_fetched is gossip verified happened-to-work-before
      if (dbpr['last_fetched'] != null) {
        score += scorefn(
          dbpr['last_fetched'],
          60 * 60 * 24 * 3,
          3,
        );
      }

      // last_suggested_bytag is an anybody-signed suggestion
      if (dbpr['last_suggested_bytag'] != null) {
        score += scorefn(
          dbpr['last_suggested_bytag'],
          60 * 60 * 24 * 2,
          1,
        );
      }

      // Prune score=0 associations
      if (score == 0) {
        continue;
      }

      output.add({
        'relay': dbpr['relay'],
        'score': score,
      });
    }

    output.sort((a, b) => b['score'].compareTo(a['score']));

    // prune everything below a score of 20, but only after the first 6 entries
    while (output.length > 6 && output.last['score'] < 20) {
      output.removeLast();
    }

    return output;
  }

  List<Map<String, dynamic>> _readRank(List<Map<String, dynamic>> dbprs) {
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var output = <Map<String, dynamic>>[];

    scorefn(int when, int fadePeriod, int base) {
      var dur = max(0, now - when); // seconds since
      var periods = (dur / fadePeriod).floor() + 1; // minimum one period
      return base ~/ periods;
    }

    for (var dbpr in dbprs) {
      var score = 0;

      // 'read' is an author-signed explicit claim of where they read
      if (dbpr['read'] || dbpr['manually_paired_read']) {
        score += 20;
      }

      // kind3 is our memory of where we are following someone
      var lastSuggestedKind3 = dbpr['last_suggested_kind3'];
      if (lastSuggestedKind3 != null) {
        score += scorefn(lastSuggestedKind3, 60 * 60 * 24 * 30, 7);
      }

      // nip05 is an unsigned dns-based author claim of using this relay
      var lastSuggestedNip05 = dbpr['last_suggested_nip05'];
      if (lastSuggestedNip05 != null) {
        score += scorefn(lastSuggestedNip05, 60 * 60 * 24 * 15, 4);
      }

      // last_fetched is gossip verified happened-to-work-before
      var lastFetched = dbpr['last_fetched'];
      if (lastFetched != null) {
        score += scorefn(lastFetched, 60 * 60 * 24 * 3, 3);
      }

      // last_suggested_bytag is an anybody-signed suggestion
      var lastSuggestedBytag = dbpr['last_suggested_bytag'];
      if (lastSuggestedBytag != null) {
        score += scorefn(lastSuggestedBytag, 60 * 60 * 24 * 2, 1);
      }

      // Prune score=0 associations
      if (score == 0) {
        continue;
      }

      output.add({'relay': dbpr['relay'], 'score': score});
    }

    output.sort((a, b) => b['score'].compareTo(a['score']));

    // prune everything below a score 20, but only after the first 6 entries
    while (output.length > 6 && output.last['score'] < 20) {
      output.removeLast();
    }

    return output;
  }
}

class DbPersonRelay {
  dynamic person;
  String relay;
  int lastFetched;
  int lastSuggestedKind3;
  int lastSuggestedNip05;
  int lastSuggestedBytag;
  bool read;
  bool write;
  bool manuallyPairedRead;
  bool manuallyPairedWrite;

  DbPersonRelay(
      {required this.person,
      required this.relay,
      required this.lastFetched,
      required this.lastSuggestedKind3,
      required this.lastSuggestedNip05,
      required this.lastSuggestedBytag,
      required this.read,
      required this.write,
      required this.manuallyPairedRead,
      required this.manuallyPairedWrite});

  Map<String, dynamic> toMap() {
    return {
      'person': person,
      'relay': relay,
      'last_fetched': lastFetched,
      'last_suggested_kind3': lastSuggestedKind3,
      'last_suggested_nip05': lastSuggestedNip05,
      'last_suggested_bytag': lastSuggestedBytag,
      'read': read,
      'write': write,
      'manuallyPairedRead': manuallyPairedRead,
      'manuallyPairedWrite': manuallyPairedWrite,
    };
  }
}

class Tuple2<T1, T2> {
  T1 value1;
  T2 value2;

  Tuple2(this.value1, this.value2);
}

class Direction {
  static const Direction write = Direction._("write");
  static const Direction read = Direction._("read");

  final String _value;

  const Direction._(this._value);

  @override
  String toString() => _value;
}
