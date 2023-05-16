import 'package:camelus/helpers/helpers.dart';
import 'package:test/test.dart';
import 'dart:convert';

void main() {
  group('Helpers', () {
    final helpers = Helpers();

    test('getRandomString generates string of correct length', () {
      final randomString = helpers.getRandomString(10);
      expect(randomString.length, 10);
    });

    test('getUuid generates a valid UUID', () {
      final uuid = helpers.getUuid();
      final uuidRegEx = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false);
      expect(uuidRegEx.hasMatch(uuid), true);
    });

    test('getSecureRandomString generates a base64Url encoded string', () {
      final randomString = helpers.getSecureRandomString(10);
      expect(base64Url.decode(randomString).length, 10);
    });

    test('getSecureRandomHex generates a hexadecimal string', () {
      final randomHex = helpers.getSecureRandomHex(10);
      final hexRegEx = RegExp(r'^[0-9a-fA-F]+$');
      expect(hexRegEx.hasMatch(randomHex), true);
      expect(randomHex.length, 20); // 2 characters for each byte
    });

    test('encodeBech32 and decodeBech32 are inverses', () {
      const hex = '1e1a76e8dc8f8c82eacb5ea02a1e87a2f172dd';
      const hrp = 'test';

      final bech32 = helpers.encodeBech32(hex, hrp);
      final decoded = helpers.decodeBech32(bech32);

      expect(decoded[0], hex);
      expect(decoded[1], hrp);
    });

    test('getPubkeysFromTags extracts pubkeys correctly', () {
      const tags = [
        ['p', 'pubkey1'],
        ['e', 'event1'],
        ['p', 'pubkey2'],
      ];

      final pubkeys = helpers.getPubkeysFromTags(tags);
      expect(pubkeys, ['pubkey1', 'pubkey2']);
    });

    test('getEventsFromTags extracts events correctly', () {
      final tags = [
        ['p', 'pubkey1'],
        ['e', 'event1'],
        ['p', 'pubkey2'],
        ['e', 'event2'],
      ];

      final events = helpers.getEventsFromTags(tags);
      expect(events, ['event1', 'event2']);
    });
  });
}
