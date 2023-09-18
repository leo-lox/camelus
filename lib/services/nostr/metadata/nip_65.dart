import 'dart:developer';

import 'package:camelus/db/queries/db_note_queries.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/nostr_request_query.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';
import 'package:camelus/services/nostr/relays/relays_picker.dart';
import 'package:isar/isar.dart';

class Nip65 {
  final Isar _db;

  Nip65(this._db);

  Future<MinimalRelaySet> calcMinimalRelaySet({
    required List<String> pubkeys,
    int desiredCoverage = 2,
    List<String> preferConnectedRelays = const [],
  }) async {
    Map<String, int> pubkeyCounts = {
      //'pubkey2': 2,
      //'pubkey3': 1,
    };
    for (var pubkey in pubkeys) {
      pubkeyCounts[pubkey] = desiredCoverage;
    }

    var relayMetadataTmp = await DbNoteQueries.kindPubkeysFuture(_db,
        kind: 10002, pubkeys: pubkeys);

    var relayMetadata = relayMetadataTmp.map((e) => e.toNostrNote()).toList();

    // if duplicate pubkey keep the latest
    var relayMetadataMap = <String, NostrNote>{};
    for (var note in relayMetadata) {
      if (relayMetadataMap.containsKey(note.pubkey)) {
        if (note.created_at > relayMetadataMap[note.pubkey]!.created_at) {
          relayMetadataMap[note.pubkey] = note;
        }
      } else {
        relayMetadataMap[note.pubkey] = note;
      }
    }

    //log("relayMetadataMap: $relayMetadataMap");

    // caclute relay scores => higher score means included by x pubkeys in tags
    Map<String, RelayScore> relayScores = {};
    for (var note in relayMetadataMap.values) {
      var writeTags = note.tags.where((element) {
        return element.recommended_relay == null ||
            element.recommended_relay == "write";
      });
      for (var tag in writeTags) {
        String relayUrl;
        try {
          relayUrl = RelayAddressParser.parseAddress(tag.value);
        } catch (e) {
          log(e.toString());
          continue;
        }

        var boost = 0;
        if (preferConnectedRelays.contains(relayUrl)) {
          boost = 2;
        }
        relayScores[tag.value] ??= RelayScore(relayUrl: relayUrl, boost: boost);
        relayScores[tag.value]!.addPubkey(note.pubkey);
      }
    }

    // sort relays by score
    var sortedRelays = relayScores.values.toList();
    sortedRelays.sort((a, b) => b.score.compareTo(a.score));

    //log("relayScores: $relayScores");

    // int => how mutch coverage the relay has
    Map<String, List<String>> finalRelays = {};

    for (var relayScore in sortedRelays) {
      for (var pubkeyEntry in pubkeyCounts.entries) {
        if (relayScore.pubkeys.contains(pubkeyEntry.key)) {
          if (pubkeyEntry.value == 0) {
            continue;
          }

          finalRelays[relayScore.relayUrl] ??= [];
          finalRelays[relayScore.relayUrl]!.add(pubkeyEntry.key);
          pubkeyCounts[pubkeyEntry.key] = pubkeyEntry.value - 1;
        }
      }
    }

    //log("finalRelays: $finalRelays");
    pubkeyCounts.removeWhere((key, value) => value == 0);
    //log("missingRelays: $pubkeyCounts");
    var missingPubkeys = pubkeyCounts.keys.toList();

    List<RelayAssignment> relayAssignments = [];
    for (var relayEntry in finalRelays.entries) {
      relayAssignments.add(
          RelayAssignment(relayUrl: relayEntry.key, pubkeys: relayEntry.value));
    }

    return MinimalRelaySet(
        relayAssignments: relayAssignments, missingWithNoRelay: missingPubkeys);
  }

  // split up the request into multiple requests and remove all authors that are not in the assignment
  // string is relay url
  static Map<String, NostrRequestQuery> splitUpRequests({
    required NostrRequestQuery request,
    required List<RelayAssignment> assignments,
  }) {
    if (assignments.isEmpty) {
      return {};
    }

    Map<String, NostrRequestQuery> result = {};

    for (var assignment in assignments) {
      NostrRequestQuery newRequest = NostrRequestQuery.clone(request);

      // remove all authors that are not in the assignment
      if (newRequest.body.authors != null) {
        newRequest.body.authors!
            .removeWhere((element) => !assignment.pubkeys.contains(element));
      }

      if (newRequest.body2?.authors != null) {
        newRequest.body2!.authors!
            .removeWhere((element) => !assignment.pubkeys.contains(element));
      }

      if (newRequest.body.hastagP != null) {
        newRequest.body.hastagP!
            .removeWhere((element) => !assignment.pubkeys.contains(element));
      }

      if (newRequest.body2?.hastagP != null) {
        newRequest.body2!.hastagP!
            .removeWhere((element) => !assignment.pubkeys.contains(element));
      }

      if (newRequest.body.authors?.isEmpty ?? false) {
        newRequest.body.authors = null;
      }

      if (newRequest.body2?.authors?.isEmpty ?? false) {
        newRequest.body2!.authors = null;
      }

      if (newRequest.body.authors == null &&
          newRequest.body.hastagP == null &&
          newRequest.body2?.hastagP == null &&
          newRequest.body2?.hastagP == null) {
        continue;
      }

      result[assignment.relayUrl] = newRequest;
    }
    return result;
  }
}

class MinimalRelaySet {
  List<RelayAssignment> relayAssignments = [];
  List<String> missingWithNoRelay = [];

  MinimalRelaySet({
    required this.relayAssignments,
    required this.missingWithNoRelay,
  });

  @override
  String toString() {
    return "relayAssignments: $relayAssignments, missingPubkeys: $missingWithNoRelay";
  }
}

class RelayScore {
  String relayUrl;
  List<String> pubkeys = [];
  int boost;
  int get score => pubkeys.length + boost;
  RelayScore({
    required this.relayUrl,
    this.boost = 0,
  });
  addPubkey(String pubkey) {
    if (!pubkeys.contains(pubkey)) {
      pubkeys.add(pubkey);
    }
  }

  @override
  String toString() {
    return "relayUrl: $relayUrl, score: $score";
  }
}
