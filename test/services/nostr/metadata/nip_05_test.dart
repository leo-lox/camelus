
import 'package:camelus/services/nostr/metadata/nip_05.dart';
import 'package:test/test.dart';

void main() {
  group('Nip05', () {
    late Nip05 nip05;

    setUp(() {
      nip05 = Nip05();
    });

    test('should throw exception if nip05 or pubkey is empty', () {
      expect(() => nip05.checkNip05('', ''), throwsA(isA<Exception>()));
    });

    test('should return a result with valid and lastCheck fields', () async {
      String exampleNip05 = 'leo@lox.de';
      String examplePubkey = 'example_pubkey'; //non existing pubkey

      Map<String, dynamic> result =
          await nip05.checkNip05(exampleNip05, examplePubkey);

      expect(result, isNotEmpty);
      expect(result, containsPair('valid', isA<bool>()));
      expect(result, containsPair('lastCheck', isA<int>()));
    });
    test('check if invalid', () async {
      String exampleNip05 = 'leo@lox.de';
      String examplePubkey = 'example_pubkey'; //non existing pubkey

      Map<String, dynamic> result =
          await nip05.checkNip05(exampleNip05, examplePubkey);

      expect(result, isNotEmpty);
      expect(result['valid'], false);
    });

    test('check if valid', () async {
      String exampleNip05 = 'leo@lox.de';
      String examplePubkey =
          '717ff238f888273f5d5ee477097f2b398921503769303a0c518d06a952f2a75e';

      Map<String, dynamic> result =
          await nip05.checkNip05(exampleNip05, examplePubkey);

      expect(result, isNotEmpty);
      expect(result['valid'], true);
    });
  });
}
