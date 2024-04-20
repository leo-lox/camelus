import 'package:camelus/services/nostr/relays/relays_ranking.dart';
import 'package:isar/isar.dart';
import 'package:camelus/data_layer/db/entities/db_relay_tracker.dart';

class RelaysPicker {
  Isar db;
  late RelaysRanking relaysRanking;

  Map<String, int> pubkeyCounts = {
    //'pubkey2': 2,
    //'pubkey3': 1,
  };

  Map<String, RelayAssignment> relayAssignments = {
    //'relay1':
    //    RelayAssignment(relayUrl: 'relay1', pubkeys: ['pubkey1', 'pubkey2']),
    //'relay2': RelayAssignment(relayUrl: 'relay2', pubkeys: ['pubkey3']),
  };

  Map<String, Map<String, int>> personRelayScores = {
    //'pubkey2': {'relay1': 7, 'relay2': 8},
  };

  Map<String, int> _excludedRelays = {
    //'relay1': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch,
    //'relay2': DateTime.now().add(Duration(hours: 2)).millisecondsSinceEpoch,
  };

  RelaysPicker({required this.db}) {
    relaysRanking = RelaysRanking(db: db);
  }

  Future<void> init(
      {required List<String> pubkeys, required int coverageCount}) async {
    for (var pubkey in pubkeys) {
      pubkeyCounts[pubkey] = coverageCount;
    }

    // populate personRelayScores
    for (var pubkey in pubkeys) {
      var scoresList =
          await relaysRanking.getBestRelays(pubkey, Direction.read);
      if (scoresList.isEmpty) {
        continue;
      }

      Map<String, int> scoresMap = {
        //'wss://relay.damus.io': 10,
      };

      for (Map listItem in scoresList) {
        scoresMap[listItem["relay"]] = listItem["score"];
      }

      personRelayScores[pubkey] = scoresMap;
    }
    return;
  }

  set setExcludedRelays(Map<String, int> value) {
    _excludedRelays = value;
  }

  String pick(List<String> pubkeys, {int? limit}) {
    List<String> pubkeysToPickFrom = [];
    //todo debug if sync impacts performace
    var rawResults =
        db.dbRelayTrackers.filter().pubkeyIsNotEmpty().findAllSync();
    for (var entry in rawResults) {
      if (entry.relays.isEmpty) {
        continue;
      }
      for (var relay in entry.relays) {
        if (relay.relayUrl == null) {
          continue;
        }
        if (relay.relayUrl!.isEmpty) {
          continue;
        }
        pubkeysToPickFrom.add(relay.relayUrl!);
      }
    }

    bool atMaxRelays = relayAssignments.length >=
        15; //todo move to settings  hooks.getMaxRelays();

// Maybe include excluded relays
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _excludedRelays.removeWhere((k, v) => v > now);

    if (pubkeyCounts.isEmpty) {
      throw Exception('NoPeopleLeft');
    }

    // combine list of maps into one list containing the map
    List allRelays = pubkeysToPickFrom;
    //List allRelays = tracker.values.; //hooks.getAllRelays();

    if (allRelays.isEmpty) {
      throw Exception('NoRelays');
    }

// Keep score for each relay
    Map scoreboard = {for (var e in allRelays) e: 0};

// Assign scores to relays from each pubkey
    personRelayScores.forEach((pubkeyhex, relayScores) {
      // Skip if this pubkey doesn't need any more assignments
      if (pubkeyCounts.containsKey(pubkeyhex)) {
        if (pubkeyCounts[pubkeyhex] == 0) {
          // person doesn't need anymore
          return;
        }
      } else {
        return; // person doesn't need any
      }

      // Add scores of their relays
      relayScores.forEach((relay, score) {
        // Skip relays that are excluded
        if (_excludedRelays.containsKey(relay)) {
          return;
        }

        // If at max, skip relays not already connected
        if (atMaxRelays && false) {
          // atMaxRelays && !hooks.isRelayConnected(relay)
          return;
        }

        // Skip if relay is already assigned this pubkey
        if (relayAssignments.containsKey(relay)) {
          if (relayAssignments[relay]!.pubkeys.contains(pubkeyhex)) {
            return;
          }
        }

        // Add the score
        scoreboard.update(relay, (value) => value + score);
      });
    });

// Adjust all scores based on relay rank and relay success rate
// TBD to add this kind of feature back.
    //scoreboard.forEach((url, score) {
    //  scoreboard[url] = hooks.adjustScore(url, score);
    //});

    var winner = scoreboard.entries.reduce((a, b) => a.value > b.value ? a : b);

    String winningUrl = winner.key;
    int winningScore = winner.value;

    if (winningScore == 0) {
      throw Exception('NoProgress $winningUrl');
    }

// Now sort out which public keys go with that relay
    List coveredPublicKeys = () {
      List pubkeysSeekingRelays = pubkeyCounts.entries
          .where((e) => e.value > 0)
          .map((e) => e.key)
          .toList();

      List coveredPubkeys = [];

      for (String pubkey in pubkeysSeekingRelays) {
        // Skip if relay is already assigned this pubkey
        if (relayAssignments.containsKey(winningUrl)) {
          if (relayAssignments[winningUrl]!.pubkeys.contains(pubkey)) {
            continue;
          }
        }

        if (personRelayScores.containsKey(pubkey)) {
          Map relayScores = personRelayScores[pubkey]!;

          if (relayScores.keys.any((e) => e == winningUrl)) {
            coveredPubkeys.add(pubkey);

            if (pubkeyCounts.containsKey(pubkey)) {
              if (pubkeyCounts[pubkey]! > 0) {
                pubkeyCounts[pubkey] = pubkeyCounts[pubkey]! - 1;
              }
            }
          }
        }
      }

      return coveredPubkeys;
    }();

    if (coveredPublicKeys.isEmpty) {
      throw Exception('NoProgress');
    }

// Only keep pubkeyCounts that are still >0
    pubkeyCounts.removeWhere((k, v) => v < 1);

    var assignment = RelayAssignment(
      relayUrl: winningUrl,
      pubkeys: coveredPublicKeys
          .map((item) => item.toString())
          .toList(), // cast to string
    );

// Put assignment into relayAssignments
    if (relayAssignments.containsKey(winningUrl)) {
      relayAssignments[winningUrl]!.mergeIn(assignment);
    } else {
      relayAssignments[winningUrl] = assignment;
    }

    return winningUrl;
  }

  RelayAssignment? getRelayAssignment(String relayUrl) {
    return relayAssignments[relayUrl];
  }
}

class RelayAssignment {
  String relayUrl;
  List<String> pubkeys;

  RelayAssignment({required this.relayUrl, required this.pubkeys});

  void mergeIn(RelayAssignment other) {
    if (other.relayUrl != relayUrl) {
      throw Exception('Cannot merge different relays');
    }
    pubkeys.addAll(other.pubkeys);
  }
}
