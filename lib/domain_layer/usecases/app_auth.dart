import 'dart:async';
import 'dart:convert';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:ndk_amber/ndk_amber.dart';
import 'package:riverpod/riverpod.dart';
import '../../presentation_layer/providers/signer_provider.dart';
import '../entities/stored_account.dart';

/// This class is used to store and retrive user information from secure storage. \
/// the storage keys [nostrKeys] and [amber] are used to store the user's keypair and amber public key respectively.
class AppAuth {
  static FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  static final amber = Amberflutter();

  /// logs in with amber and sets the storage flag for amber
  static Future<AmberEventSigner> amberRegister() async {
    final amberSigner = await _amberRegisterPopup();
    await secureStorage.write(key: "amber", value: amberSigner.publicKey);

    return amberSigner;
  }

  static Future<AmberEventSigner> _amberRegisterPopup() async {
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
        const Permission(
          type: "nip44_encrypt",
        ),
        const Permission(
          type: "nip44_decrypt",
        ),
        const Permission(type: "sign_event", kind: 0),
        const Permission(type: "sign_event", kind: 1),
        const Permission(type: "sign_event", kind: 2),
        const Permission(type: "sign_event", kind: 3),
        const Permission(type: "sign_event", kind: 4),
        const Permission(type: "sign_event", kind: 5),
        const Permission(type: "sign_event", kind: 6),
        const Permission(type: "sign_event", kind: 7),
        // nip 65
        const Permission(type: "sign_event", kind: 10002),
      ],
    );

    final npub = amberValue['signature'] ?? '';
    final pubkeyHex = Nip19.decode(npub);

    final amberFlutterDS = AmberFlutterDS(amber);
    final amberSigner =
        AmberEventSigner(publicKey: pubkeyHex, amberFlutterDS: amberFlutterDS);
    return amberSigner;
  }

  static Future<AmberEventSigner> _amberLogin(String amberPubkey) async {
    final installed = await amber.isAppInstalled();
    if (!installed) {
      throw Exception('Amber is not installed');
    }
    final amberFlutterDS = AmberFlutterDS(amber);
    final amberSigner = AmberEventSigner(
        publicKey: amberPubkey, amberFlutterDS: amberFlutterDS);
    return amberSigner;
  }

  /// tries to login with stored account data
  /// returns the event signer if successful, null otherwise
  static Future<EventSigner?> loginWithStoredAccount({
    required StartupAccountData startupAccountData,
    required SingerNotifier signerNoti,
    required Ndk ndk,
  }) async {
    switch (startupAccountData.loginType) {
      case LoginType.privateKey:
        final keyPair = startupAccountData.account!.keyPair!;
        final signer = Bip340EventSigner(
          privateKey: keyPair.privateKey,
          publicKey: keyPair.publicKey,
        );
        ndk.accounts.loginExternalSigner(signer: signer);
        signerNoti.setSigner(signer);

        return signer;
      case LoginType.amber:
        final amberPubkey = startupAccountData.account!.pubkey!;
        final amberSigner = await _amberLogin(amberPubkey);

        ndk.accounts.loginExternalSigner(signer: amberSigner);
        signerNoti.setSigner(amberSigner);

        return amberSigner;

      case LoginType.bunkerConnection:
        if (startupAccountData.account!.bunkerConnection == null) {
          return null;
        }
        final connection = startupAccountData.account!.bunkerConnection!;
        try {
          print("Logging in with bunker connection");
          await ndk.accounts.loginWithBunkerConnection(
            connection: connection,
            bunkers: ndk.bunkers,
            authCallback: (a) {
              print("Bunker auth callback: $a");
            },
          );
          print("Logged in with bunker connection");
          final signer = ndk.accounts.getLoggedAccount()!.signer;
          signerNoti.setSigner(signer);
          return signer;
        } catch (_) {
          return null;
        }

      case LoginType.register:
        return null;
    }
  }

  static Future<StartupAccountData> getStartupAccountData() async {
    final activeAccountPubkey =
        await secureStorage.read(key: "activeAccountPubkey");
    final storedAccountsString =
        await secureStorage.read(key: "storedAccounts");

    if (activeAccountPubkey == null || storedAccountsString == null) {
      return StartupAccountData(
        loginType: LoginType.register,
      );
    }

    final storedAccounts = jsonDecode(storedAccountsString) as List;
    final storedAccountsList =
        storedAccounts.map((e) => LocalStorageAccount.fromJson(e)).toList();

    // check if pubkey matches

    LocalStorageAccount matchedAccount;
    try {
      matchedAccount = storedAccountsList.firstWhere(
        (account) => account.pubkey == activeAccountPubkey,
      );
    } catch (e) {
      // if no match found, use last account or register if list is empty
      matchedAccount = storedAccountsList.isNotEmpty
          ? storedAccountsList.last
          : LocalStorageAccount(loginType: LoginType.register);
    }

    return StartupAccountData(
      loginType: matchedAccount.loginType,
      account: matchedAccount,
    );
  }

  static Future<void> addStoredAccount({
    required LocalStorageAccount account,
    bool setActive = true,
  }) async {
    final storedAccountsString =
        await secureStorage.read(key: "storedAccounts");
    List<LocalStorageAccount> storedAccounts = [];
    if (storedAccountsString != null) {
      final storedAccountsJson = jsonDecode(storedAccountsString) as List;
      storedAccounts = storedAccountsJson
          .map((e) => LocalStorageAccount.fromJson(e))
          .toList();
    }
    storedAccounts.add(account);
    await secureStorage.write(
      key: "storedAccounts",
      value: jsonEncode(storedAccounts.map((e) => e.toJson()).toList()),
    );
    if (setActive && account.pubkey != null) {
      await secureStorage.write(
        key: "activeAccountPubkey",
        value: account.pubkey!,
      );
    }
  }

  /// deltes the keys from storage.
  /// This is used to log out the user
  static Future<void> clearAllAccounts() async {
    await secureStorage.delete(
      key: "activeAccountPubkey",
    );
    await secureStorage.delete(key: "storedAccounts");
  }
}
