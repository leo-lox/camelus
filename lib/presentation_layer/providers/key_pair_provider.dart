import 'package:camelus/helpers/bip340.dart';
import 'package:riverpod/riverpod.dart';

import '../../domain_layer/entities/key_pair.dart';

final keyPairProvider = StateProvider<KeyPairWrapper>((ref) {
  KeyPairWrapper keyPairWrapper;

  keyPairWrapper = KeyPairWrapper(keyPair: null);

  return keyPairWrapper;
});

class KeyPairWrapper {
  KeyPair? keyPair;
  KeyPairWrapper({required this.keyPair});

  setKeyPair(KeyPair myKeyPair) {
    keyPair = myKeyPair;
  }

  removeKeyPair() {
    keyPair = null;
  }
}
