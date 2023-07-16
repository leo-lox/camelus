import 'package:camelus/services/nostr/relays/relays_picker.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:flutter_test/flutter_test.dart';
import 'package:test/test.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  SharedPreferences.setMockInitialValues({}); //set values here

  //TestWidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  group('picker EmptyTracker', () {
    var picker = RelaysPicker();
    picker.relayTracker.tracker = {};

    final mockSharedPreferences = MockSharedPreferences();
    when(mockSharedPreferences.getString('')).thenReturn('mock');

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
    final mockSharedPreferences = MockSharedPreferences();
    when(mockSharedPreferences.getString('')).thenReturn('mock');
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
  });
}
