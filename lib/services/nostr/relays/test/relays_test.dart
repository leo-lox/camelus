import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getRelaysPubkeyMatch', () {
    test('non-existing-pubkey', () {
      var relays = Relays();
      var result = relays.getRelaysPubkeyMatch(["non-existing-pubkey"]);

      expect(result, {});
    });

    test('existing-pubkey', () {
      var relays = Relays();
      // modifying global state
      relays.relayTracker.tracker["existing-pubkey"] = {
        "existing-relay-url": {
          "lastSuggestedKind3": 0,
          "lastSuggestedNip05": 0,
          "lastSuggestedBytag": 0,
        }
      };

      var result = relays.getRelaysPubkeyMatch(["existing-pubkey"]);

      expect(result, {
        "existing-relay-url": ["existing-pubkey"]
      });
    });
  });
}
