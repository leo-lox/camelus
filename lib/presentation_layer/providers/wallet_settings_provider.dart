import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys — add a new const here when introducing a new experimental feature.
const _kWalletKey = 'experimental_wallet_enabled';

/// Holds the enabled/disabled state for every experimental feature.
/// Add a new named field (+ copyWith param) to expose a new feature.
class ExperimentalFeaturesState {
  const ExperimentalFeaturesState({this.wallet = false});

  final bool wallet;

  ExperimentalFeaturesState copyWith({bool? wallet}) {
    return ExperimentalFeaturesState(wallet: wallet ?? this.wallet);
  }
}

class ExperimentalFeaturesNotifier extends Notifier<ExperimentalFeaturesState> {
  @override
  ExperimentalFeaturesState build() {
    _load();
    return const ExperimentalFeaturesState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = ExperimentalFeaturesState(
      wallet: prefs.getBool(_kWalletKey) ?? false,
    );
  }

  Future<void> setWallet(bool enabled) async {
    state = state.copyWith(wallet: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWalletKey, enabled);
  }
}

final experimentalFeaturesProvider =
    NotifierProvider<ExperimentalFeaturesNotifier, ExperimentalFeaturesState>(
      ExperimentalFeaturesNotifier.new,
    );
