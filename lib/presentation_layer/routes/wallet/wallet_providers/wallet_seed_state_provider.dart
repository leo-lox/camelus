// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../../providers/ndk_provider.dart';

final walletSeedStateProvider =
    NotifierProvider<WalletSeedInitialState, WalletSeedState>(
      WalletSeedInitialState.new,
    );

class LocalStoredSeed {
  final String seedPhrase;
  final Language language;
  final bool passphraseRequired;

  LocalStoredSeed({
    required this.seedPhrase,
    this.language = Language.english,
    this.passphraseRequired = false,
  });

  Map<String, Object> toJson() {
    return {
      'seedPhrase': seedPhrase,
      'language': language.name,
      'passphraseRequired': passphraseRequired,
    };
  }

  String toJsonString() {
    return json.encode(toJson());
  }

  factory LocalStoredSeed.fromJson(Map<String, dynamic> json) {
    return LocalStoredSeed(
      seedPhrase: json['seedPhrase'],
      language: Language.values.firstWhere((e) => e.name == json['language']),
      passphraseRequired: json['passphraseRequired'],
    );
  }

  factory LocalStoredSeed.fromCashuUserSeedphrase(CashuUserSeedphrase seed) {
    return LocalStoredSeed(
      seedPhrase: seed.seedPhrase,
      language: seed.language,
      passphraseRequired: seed.passphrase.isNotEmpty,
    );
  }
}

class WalletSeedState {
  final CashuUserSeedphrase? cashuSeed;
  final bool passwordRequired;
  final bool isLoading;

  WalletSeedState({
    this.cashuSeed,
    this.passwordRequired = false,
    this.isLoading = true,
  });

  WalletSeedState copyWith({
    CashuUserSeedphrase? cashuSeed,
    bool? passwordRequired,
    bool? isLoading,
  }) {
    return WalletSeedState(
      cashuSeed: cashuSeed ?? this.cashuSeed,
      passwordRequired: passwordRequired ?? this.passwordRequired,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class WalletSeedInitialState extends Notifier<WalletSeedState> {
  FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  Ndk get _ndk => ref.read(ndkProvider);

  @override
  WalletSeedState build() {
    getSeedFromStorage();
    return WalletSeedState(cashuSeed: null, isLoading: true);
  }

  Future<WalletSeedState?> getSeedFromStorage({String? password}) async {
    final seed = await secureStorage.read(key: 'cashu_seed');

    if (seed != null) {
      final storedSeed = LocalStoredSeed.fromJson(json.decode(seed));

      if (storedSeed.passphraseRequired && password == null) {
        state = state.copyWith(passwordRequired: true, isLoading: false);
        return null;
      }

      state = state.copyWith(
        passwordRequired: false,
        isLoading: false,
        cashuSeed: CashuUserSeedphrase(
          seedPhrase: storedSeed.seedPhrase,
          language: storedSeed.language,
          passphrase: password ?? '',
        ),
      );

      if (state.cashuSeed != null) {
        _ndk.cashu.setCashuSeedPhrase(state.cashuSeed!);
      }

      return state;
    }

    state = state.copyWith(isLoading: false);
    return null;
  }

  Future<void> setSeedStorage(CashuUserSeedphrase seed) async {
    await secureStorage.write(
      key: 'cashu_seed',
      value: LocalStoredSeed.fromCashuUserSeedphrase(seed).toJsonString(),
    );
  }

  void setSeed(CashuUserSeedphrase seed) {
    state = state.copyWith(
      cashuSeed: seed,
      isLoading: false,
      passwordRequired: false,
    );
    _ndk.cashu.setCashuSeedPhrase(seed);
  }

  Future<void> deleteSeed() async {
    // Remove all known wallets first
    final wallets = await _ndk.wallets.getWallets();
    for (final wallet in wallets) {
      await _ndk.wallets.removeWallet(wallet.id);
    }

    await secureStorage.delete(key: 'cashu_seed');
    state = WalletSeedState(cashuSeed: null, isLoading: false);
  }

  Future<String> generateSeedPhrase({
    Language language = Language.english,
    String passphrase = '',
  }) async {
    final newSeed = CashuSeed.generateSeedPhrase(
      length: MnemonicLength.words24,
    );

    return newSeed;
  }
}
