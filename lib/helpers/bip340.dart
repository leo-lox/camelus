import 'package:bip340/bip340.dart' as bip340;
import 'package:camelus/helpers/helpers.dart';

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

class KeyPair {
  /// [privateKey] is a 32-bytes hex-encoded string
  final String privateKey;

  /// [publicKey] is a 32-bytes hex-encoded string
  final String publicKey;

  /// [privateKeyHr] is a human readable private key e.g. nsec
  final String privateKeyHr;

  /// [publicKeyHr] is a human readable public key e.g. npub
  final String publicKeyHr;

  KeyPair({
    required this.privateKey,
    required this.publicKey,
    required this.privateKeyHr,
    required this.publicKeyHr,
  });

  Map<String, dynamic> toJson() => {
        'privateKey': privateKey,
        'publicKey': publicKey,
        'privateKeyHr': privateKeyHr,
        'publicKeyHr': publicKeyHr,
      };

  factory KeyPair.fromJson(Map<String, dynamic> json) => KeyPair(
        privateKey: json['privateKey'],
        publicKey: json['publicKey'],
        privateKeyHr: json['privateKeyHr'],
        publicKeyHr: json['publicKeyHr'],
      );
}
