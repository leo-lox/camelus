import 'package:flutter/foundation.dart';
import 'dart:math';

class RelaysRanking {
  Future<List<dynamic>> getBestRelays(String pubkeyHex, Direction dir) async {
    final sql = "SELECT person, relay, last_fetched, last_suggested_kind3, "
        "last_suggested_nip05, last_suggested_bytag, read, write, "
        "manually_paired_read, manually_paired_write "
        "FROM person_relay WHERE person=?";

    final rankedRelays = (() {
      //final maybeDb = "GLOBALS.db.blockingLock()";
      //final db = maybeDb.value;
      //final stmt = db.prepare(sql);
      //stmt.rawBindParameter(1, pubkeyHex);
      //final rows = stmt.rawQuery();

      final dbprs = <DbPersonRelay>[];
      //while (rows.hasNext()) {
      //  final row = rows.next();
      //  final s = row.get(1);
      //  try {
      //    final url = RelayUrl.tryFromStr(s);
      //    final dbpr = DbPersonRelay(
      //      person: row.get(0),
      //      relay: url,
      //      lastFetched: row.get(2),
      //      lastSuggestedKind3: row.get(3),
      //      lastSuggestedNip05: row.get(4),
      //      lastSuggestedBytag: row.get(5),
      //      read: row.get(6),
      //      write: row.get(7),
      //      manuallyPairedRead: row.get(8),
      //      manuallyPairedWrite: row.get(9),
      //    );
      //    dbprs.add(dbpr);
      //  } on Exception {
      //    // Just skip over bad relay URLs
      //  }
      //}

      switch (dir) {
        case Direction.write:
          return _writeRank(dbprs as List<Map<String, dynamic>>);
        case Direction.read:
          return _readRank(dbprs as List<Map<String, dynamic>>);
      }
    });

    final rankedRelaysList = rankedRelays as List<Map<String, dynamic>>;
    final numRelaysPerPerson = 2; //todo: move this to settings

    // If we can't get enough of them, extend with some of our relays
    // at whatever the lowest score of their last one was
    if (rankedRelaysList.length < (numRelaysPerPerson + 1)) {
      final howManyMore = (numRelaysPerPerson + 1) - rankedRelaysList.length;
      final lastScore =
          rankedRelaysList.isEmpty ? 20 : rankedRelaysList.last.value2;
      final additional = GLOBALS.relayTracker.allRelays.entries
          .where((r) =>
              !rankedRelaysList.any((rel) => rel.value1 == r.key) &&
              ((dir == Direction.write && r.value.write) ||
                  (dir == Direction.read && r.value.read)))
          .take(howManyMore)
          .map((r) => Tuple2(r.key.clone(), lastScore))
          .toList();
      rankedRelaysList.addAll(additional);
    }

    return rankedRelaysList;
  }
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

class DbPersonRelay {
  dynamic person;
  RelayUrl relay;
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
}

class RelayUrl {
  final String url;
  final String host;
  final int port;
  final bool ssl;

  RelayUrl(this.url, this.host, this.port, this.ssl);

  factory RelayUrl.tryFromStr(String url) {
    final uri = Uri.parse(url);
    final ssl = uri.scheme == "wss";
    final port = uri.port;
    final host = uri.host;
    return RelayUrl(url, host, port, ssl);
  }

  RelayUrl clone() => RelayUrl(url, host, port, ssl);

  @override
  String toString() => url;
}

class Tuple2 {
  final value1;
  final value2;

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
