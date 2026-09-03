import 'dart:typed_data';

import 'package:bip32_keys/bip32_keys.dart';
import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:hex/hex.dart';

import '../../helpers/bip340.dart';
import '../entities/generated_private_key.dart';

class GeneratePrivateKey {
  static GeneratedPrivateKey generateKey() {
    final mnemonic = Mnemonic.generate(
      Language.english,
      length: MnemonicLength.words24,
    );

    final sentence = mnemonic.sentence;
    final words = mnemonic.words;
    final privateKey = _getPrivkeyFromSeed(mnemonic);
    final publicKey = Bip340().getPublicKey(privateKey);

    final myKey = GeneratedPrivateKey(
      mnemonicSentence: sentence,
      mnemonicWords: words,
      privateKey: privateKey,
      publicKey: publicKey,
    );
    return myKey;
  }

  /// [returns] private key as hex string
  static String _getPrivkeyFromSeed(Mnemonic myMnemonic) {
    final Uint8List seedBytes = Uint8List.fromList(myMnemonic.entropy);
    final node = Bip32Keys.fromSeed(seedBytes);

    //  m/44'/1237'/<account>'/0/0
    final child = node.derivePath("m/44'/1237'/0'/0/0");

    final privkeyHex = HEX.encode(child.private!);

    return privkeyHex;
  }
}
