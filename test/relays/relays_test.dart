import 'dart:developer';

import 'package:camelus/models/socket_control.dart';
import 'package:camelus/services/nostr/relays/relays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getRelaysPubkeyMatch', () {
    test('non-existing-pubkey', () {
      var relays = Relays();
      var result =
          relays.getRelaysPubkeyMatchInConnected(["non-existing-pubkey"]);

      expect(result, {});
    });

    test('existing-pubkey', () {
      var relays = Relays();
      // modifying global state
      relays.connectedRelaysRead["existing-pubkey"] =
          SocketControl("id", "existing-relay-url");

      log(relays.connectedRelaysRead.toString());

      var result = relays.getRelaysPubkeyMatchInConnected(["existing-pubkey"]);

      expect(result, {
        "existing-relay-url": ["existing-pubkey"]
      });
    });
  });
}
