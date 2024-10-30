import 'dart:convert';
import 'dart:io';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';

import '../entities/key_pair.dart';

/// This class is used to store and retrive user information from secure storage. \
/// the storage keys [nostrKeys] and [amber] are used to store the user's keypair and amber public key respectively.
class AppAuth {
  static FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  static final amber = Amberflutter();

  /// logs in with amber and sets the storage flag for amber
  static Future<AmberEventSigner> amberRegister() async {
    final amberSigner = await _amberLogin();
    await secureStorage.write(key: "amber", value: amberSigner.publicKey);

    return amberSigner;
  }

  static Future<AmberEventSigner> _amberLogin() async {
    final installed = await amber.isAppInstalled();
    if (!installed) {
      throw Exception('Amber is not installed');
    }
    final amberValue = await amber.getPublicKey(
      permissions: [
        const Permission(
          type: "nip04_encrypt",
        ),
        const Permission(
          type: "nip04_decrypt",
        ),
        const Permission(type: "sign_event"),
      ],
    );

    final npub = amberValue['signature'] ?? '';
    final pubkeyHex = Nip19.decode(npub);

    final amberFlutterDS = AmberFlutterDS(amber);
    final amberSigner =
        AmberEventSigner(publicKey: pubkeyHex, amberFlutterDS: amberFlutterDS);
    return amberSigner;
  }

  static Future<KeyPair?> _setupKeys() async {
    var nostrKeysString = await secureStorage.read(key: "nostrKeys");
    if (nostrKeysString == null) {
      return null;
    }
    final myKeyPair = KeyPair.fromJson(json.decode(nostrKeysString));
    return myKeyPair;
  }

  /// gets the current used event signer based on storage
  /// null if no valid event signer is found => user needs to register
  static Future<EventSigner?> getEventSigner() async {
    final myKeyPair = await _setupKeys();

    if (myKeyPair != null) {
      final signer = Bip340EventSigner(
        privateKey: myKeyPair.privateKey,
        publicKey: myKeyPair.publicKey,
      );
      return signer;
    }

    // no amber on other platforms
    if (!Platform.isAndroid) {
      return null;
    }
    // check if amber is used
    final amberInstalled = await amber.isAppInstalled();

    if (!amberInstalled) {
      return null;
    }
    final amberPubkey = await secureStorage.read(key: "amber");

    // not registered with amber
    if (amberPubkey == null) {
      return null;
    }

    // ok to login with amber
    return await _amberLogin();
  }

  /// deltes the keys from storage.
  /// This is used to log out the user
  static Future<void> clearKeys() async {
    secureStorage.delete(
      key: "nostrKeys",
    );
    secureStorage.delete(key: "amber");
  }
}
