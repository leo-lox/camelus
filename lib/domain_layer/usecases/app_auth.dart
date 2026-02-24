import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:amberflutter/amberflutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/data_layer/repositories/signers/nip46_event_signer.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk_amber/ndk_amber.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../config/camelus_config.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation_layer/providers/signer_provider.dart';
import '../entities/stored_account.dart';

/// This class is used to store and retrive user information from secure storage. \
/// the storage keys [nostrKeys] and [amber] are used to store the user's keypair and amber public key respectively.
class AppAuth {
  static const accountStorageKey = kDebugMode
      ? "DEV_storedAccounts"
      : "storedAccounts";
  static const activeAccountPubkeyStorageKey = kDebugMode
      ? "DEV_activeAccountPubkey"
      : "activeAccountPubkey";

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
        const Permission(type: "nip04_encrypt"),
        const Permission(type: "nip04_decrypt"),
        const Permission(type: "nip44_encrypt"),
        const Permission(type: "nip44_decrypt"),
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
    final amberSigner = AmberEventSigner(
      publicKey: pubkeyHex,
      amberFlutterDS: amberFlutterDS,
    );
    return amberSigner;
  }

  static Future<AmberEventSigner> _amberLogin(String amberPubkey) async {
    final installed = await amber.isAppInstalled();
    if (!installed) {
      throw Exception('Amber is not installed');
    }
    final amberFlutterDS = AmberFlutterDS(amber);
    final amberSigner = AmberEventSigner(
      publicKey: amberPubkey,
      amberFlutterDS: amberFlutterDS,
    );
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

        try {
          final signer = Nip46EventSigner(
            connection: startupAccountData.account!.bunkerConnection!,
            requests: ndk.requests,
            broadcast: ndk.broadcast,
            cachedPublicKey: startupAccountData.account?.pubkey!,
          );
          ndk.accounts.loginExternalSigner(signer: signer);

          signerNoti.setSigner(signer);
          return signer;
        } catch (_) {
          return null;
        }

      case LoginType.readOnly:
        // For read-only accounts, use NDK's loginReadOnlyPubkey
        if (startupAccountData.account?.pubkey != null) {
          ndk.accounts.loginPublicKey(
            pubkey: startupAccountData.account!.pubkey!,
          );
        }
        return null;

      case LoginType.anon:
        return null;

      case LoginType.register:
        return null;
    }
  }

  static Future<StartupAccountData> getStartupAccountData() async {
    final activeAccountPubkey = await secureStorage.read(
      key: AppAuth.activeAccountPubkeyStorageKey,
    );
    final storedAccountsString = await secureStorage.read(
      key: AppAuth.accountStorageKey,
    );

    if (activeAccountPubkey == null || storedAccountsString == null) {
      return StartupAccountData(loginType: LoginType.anon);
    }

    final storedAccounts = jsonDecode(storedAccountsString) as List;
    final storedAccountsList = storedAccounts
        .map((e) => LocalStorageAccount.fromJson(e))
        .toList();

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
          : LocalStorageAccount(loginType: LoginType.anon);
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
    final storedAccountsString = await secureStorage.read(
      key: AppAuth.accountStorageKey,
    );
    List<LocalStorageAccount> storedAccounts = [];
    if (storedAccountsString != null) {
      final storedAccountsJson = jsonDecode(storedAccountsString) as List;
      storedAccounts = storedAccountsJson
          .map((e) => LocalStorageAccount.fromJson(e))
          .toList();
    }
    storedAccounts.add(account);
    await secureStorage.write(
      key: AppAuth.accountStorageKey,
      value: jsonEncode(storedAccounts.map((e) => e.toJson()).toList()),
    );
    if (setActive && account.pubkey != null) {
      await secureStorage.write(
        key: AppAuth.activeAccountPubkeyStorageKey,
        value: account.pubkey!,
      );
    }
  }

  /// deltes the keys from storage.
  /// This is used to log out the user
  static Future<void> clearAllAccounts() async {
    await secureStorage.delete(key: AppAuth.activeAccountPubkeyStorageKey);
    await secureStorage.delete(key: AppAuth.accountStorageKey);
  }

  static void showLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          icon: Icon(
            PhosphorIcons.lockKey(),
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(
            AppLocalizations.of(context)!.loginRegistrationRequired,
            textAlign: TextAlign.center,
          ),
          content: Text(
            AppLocalizations.of(context)!.pleaseLoginToInteract,
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/onboarding');
              },
              child: Text(AppLocalizations.of(context)!.loginRegister),
            ),
          ],
        ),
      ),
    );
  }
}
