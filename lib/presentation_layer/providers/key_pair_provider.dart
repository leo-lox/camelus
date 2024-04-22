import 'dart:convert';

import 'package:camelus/helpers/bip340.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod/riverpod.dart';

final keyPairProvider = FutureProvider<KeyPairWrapper>((ref) async {
  KeyPairWrapper keyPairWrapper;
  // load keypair from storage
  FlutterSecureStorage storage = const FlutterSecureStorage();
  var nostrKeysString = await storage.read(key: "nostrKeys");
  if (nostrKeysString == null) {
    keyPairWrapper = KeyPairWrapper();
  } else {
    var myKeyPair = KeyPair.fromJson(json.decode(nostrKeysString));
    keyPairWrapper = KeyPairWrapper(keyPair: myKeyPair);
  }

  return keyPairWrapper;
});

class KeyPairWrapper {
  KeyPair? keyPair;
  KeyPairWrapper({this.keyPair});

  setKeyPair(KeyPair myKeyPair) {
    keyPair = myKeyPair;
  }

  removeKeyPair() {
    keyPair = null;
  }
}
