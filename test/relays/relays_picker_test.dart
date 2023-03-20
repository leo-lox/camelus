import 'dart:developer';
import 'dart:math';
import 'package:camelus/services/nostr/relays/relays_picker.dart';
import 'package:test/test.dart';

void main() {
  group('picker EmptyTracker', () {
    var picker = RelaysPicker();
    picker.relayTracker.tracker = {};

    test('emptyTracker:NoPeopleLeft', () {
      picker.relayTracker.tracker = {};
      const pubkeys = ['pubkey1', 'pubkey2', 'pubkey3'];
      picker.init(pubkeys: [], coverageCount: 2);

      expect(
        () => picker.pick(pubkeys),
        throwsA(predicate((e) =>
            e is Exception && e.toString() == 'Exception: NoPeopleLeft')),
      );
    });

    test('emptyTracker:noRelays', () {
      picker.relayTracker.tracker = {};
      const pubkeys = ['pubkey1', 'pubkey2', 'pubkey3'];

      picker.init(pubkeys: pubkeys, coverageCount: 2);

      String result;
      try {
        var relayAssignments = picker.pick(pubkeys);

        result = relayAssignments.toString();
      } catch (e) {
        result = e.toString();
      }

      expect(result, "Exception: NoRelays");
    });
  });

  group("picker Populated", () {
    var picker = RelaysPicker();

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    /// pubkey,relayUrl :{, lastSuggestedKind3, lastSuggestedNip05, lastSuggestedBytag}
    var mockRelays = {
      'pubkey1': {
        'relay1': {
          'lastSuggestedKind3': now,
          'lastSuggestedNip05': now,
          'lastSuggestedBytag': now,
        },
        'relay2': {
          'lastSuggestedKind3': now,
          'lastSuggestedNip05': now,
          'lastSuggestedBytag': now,
        },
      },
      'pubkey2': {
        'relay1': {
          'lastSuggestedKind3': now,
          'lastSuggestedNip05': now,
          'lastSuggestedBytag': now,
        },
        'relay2': {
          'lastSuggestedKind3': now,
          'lastSuggestedNip05': now,
          'lastSuggestedBytag': now,
        },
      },
      'pubkey3': {
        'relay1': {
          'lastSuggestedKind3': now,
          'lastSuggestedNip05': now,
          'lastSuggestedBytag': now,
        },
        'relay2': {
          'lastSuggestedKind3': now,
          'lastSuggestedNip05': now,
          'lastSuggestedBytag': now,
        },
      }
    };

    test("description", () {
      picker.relayTracker.tracker = mockRelays;
      const pubkeys = ['pubkey1', 'pubkey2', 'pubkey3'];
      picker.init(pubkeys: pubkeys, coverageCount: 2);

      String exception = "";

      var assignment;
      var foundRelays;
      Map<String, int> excludedRelays = {};

      // todo discuss bad practice repeating code
      while (true) {
        try {
          var result = picker.pick(pubkeys);
          var assignment = picker.getRelayAssignment(result);
          if (assignment == null) {
            continue;
          }
          if (assignment.relayUrl.isEmpty) {
            continue;
          }
          foundRelays.add(assignment);

          // exclude already found relays
          excludedRelays[assignment.relayUrl] = now;

          picker.setExcludedRelays = excludedRelays;
        } catch (e) {
          exception = e.toString();
          print("catch: $e");
          break;
        }
      }

      print(
          "assignment: $assignment, exeption: $exception, foundRelays: $foundRelays, excludedRelays: $excludedRelays");

      expect(0, 0);
    });
  });
}
