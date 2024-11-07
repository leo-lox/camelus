import 'package:bip340/bip340.dart' as bip340;
import 'package:camelus/helpers/helpers.dart';

import '../domain_layer/entities/key_pair.dart';

class Bip340 {
  final _helpers = Helpers();

  /// [message] is a hex string
  /// [privateKey] is a  32-bytes hex encoded string
  /// returns a hex string
  String sign(String message, String privateKey) {
    final aux = _helpers.getSecureRandomHex(32);
    return bip340.sign(privateKey, message, aux);
  }

  /// [message] is a hex string
  /// [signature] is a hex string
  /// [publicKey] is a 32-bytes hex-encoded string
  /// true if the signature is valid otherwise false
  bool verify(String message, String signature, String? publicKey) {
    if (publicKey == null) return false;
    return bip340.verify(publicKey, message, signature);
  }

  /// [privateKey] is a 32-bytes hex-encoded string
  /// returns the public key in form of 32-bytes hex-encoded string
  String getPublicKey(String privateKey) {
    return bip340.getPublicKey(privateKey);
  }

  /// generates a new private key with a secure random generator
  KeyPair generatePrivateKey() {
    final privKey = _helpers.getSecureRandomHex(32);
    final pubKey = getPublicKey(privKey);

    final privKeyHr = _helpers.encodeBech32(privKey, 'nsec');
    final pubKeyHr = _helpers.encodeBech32(pubKey, 'npub');

    return KeyPair(
        privateKey: privKey,
        publicKey: pubKey,
        privateKeyHr: privKeyHr,
        publicKeyHr: pubKeyHr);
  }
}
