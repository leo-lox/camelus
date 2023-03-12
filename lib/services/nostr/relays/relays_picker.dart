import 'dart:developer';

import 'package:camelus/services/nostr/relays/relay_tracker.dart';
import 'package:camelus/services/nostr/relays/relays_injector.dart';

class RelaysPicker {
  late RelayTracker relayTracker;

  Map<String, int> pubkeyCounts = {
    'cd25e76b6a171b9a01a166a37dae7d217e0ccd573fb53207ca6d4d082bddc605': 1,
    //'pubkey2': 2,
    //'pubkey3': 1,
  };

  Map<String, RelayAssignment> relayAssignments = {
    //'relay1':
    //    RelayAssignment(relayUrl: 'relay1', pubkeys: ['pubkey1', 'pubkey2']),
    //'relay2': RelayAssignment(relayUrl: 'relay2', pubkeys: ['pubkey3']),
  };

  Map<String, Map<String, int>> personRelayScores = {
    'cd25e76b6a171b9a01a166a37dae7d217e0ccd573fb53207ca6d4d082bddc605': {
      'wss://relay.damus.io': 10,
      //'relay2': 5
    },
    //'pubkey2': {'relay1': 7, 'relay2': 8},
  };

  Map<String, int> excludedRelays = {
    //'relay1': DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch,
    //'relay2': DateTime.now().add(Duration(hours: 2)).millisecondsSinceEpoch,
  };

  RelaysPicker() {
    relayTracker = RelaysInjector().relayTracker;
  }

  String pick(List<String> pubkeys, {int? limit}) {
    var tracker = relayTracker.tracker;

    bool atMaxRelays = relayAssignments.length >=
        15; //todo move to settings  hooks.getMaxRelays();

// Maybe include excluded relays
    int now = DateTime.now().millisecondsSinceEpoch;
    excludedRelays.removeWhere((k, v) => v > now);

    if (pubkeyCounts.isEmpty) {
      throw Exception('NoPeopleLeft');
    }

    // combine list of maps into one list containing the map
    List allRelays = tracker.values.expand((element) => element.keys).toList();
    //List allRelays = tracker.values.; //hooks.getAllRelays();

    if (allRelays.isEmpty) {
      throw Exception('NoRelays');
    }

// Keep score for each relay
    Map scoreboard =
        Map.fromIterable(allRelays, key: (e) => e, value: (e) => 0);

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
        if (excludedRelays.containsKey(relay)) {
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
    pubkeyCounts.removeWhere((k, v) => v > 0);

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
