import 'package:camelus/services/nostr/relays/relays.dart';
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

  group('relays', () {
    final mockSharedPreferences = MockSharedPreferences();
    when(mockSharedPreferences.getString('')).thenReturn('mock');

    var picker = RelaysPicker();

    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

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

    test('get optimal relays', () async {
      picker.relayTracker.tracker = mockRelays;
      const pubkeys = ['pubkey1', 'pubkey2', 'pubkey3'];
      picker.init(pubkeys: pubkeys, coverageCount: 2);

      var relays = Relays();
      var result = await relays.getOptimalRelays(pubkeys);

      var checkList = [
        RelayAssignment(
            relayUrl: "relay2", pubkeys: ["pubkey1", "pubkey2", "pubkey3"]),
        RelayAssignment(
            relayUrl: "relay1", pubkeys: ["pubkey1", "pubkey2", "pubkey3"]),
      ];

      // check if all values in checkList are in result
      for (var i = 0; i < checkList.length; i++) {
        expect(result[i].relayUrl, checkList[i].relayUrl);
      }
    });
  });
}
