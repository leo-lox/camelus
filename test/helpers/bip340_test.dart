import 'package:camelus/helpers/bip340.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:hex/hex.dart';
import 'package:test/test.dart';

void main() {
  group('Bip340', () {
    test('sign and verify', () {
      final bip340 = Bip340();
      final keyPair = bip340.generatePrivateKey();
      final message = 'Hello, World!';
      // message to HEX
      final messageHex = HEX.encode(message.codeUnits);
      final signature = bip340.sign(messageHex, keyPair.privateKey);
      expect(bip340.verify(messageHex, signature, keyPair.publicKey), isTrue);
    });

    test('getPublicKey', () {
      final bip340 = Bip340();
      final keyPair = bip340.generatePrivateKey();
      expect(
          bip340.getPublicKey(keyPair.privateKey), equals(keyPair.publicKey));
    });
  });
}
