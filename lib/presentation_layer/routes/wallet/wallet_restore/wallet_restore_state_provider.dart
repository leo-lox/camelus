// ignore_for_file: experimental_member_use

import 'dart:async';

import 'package:ndk/ndk.dart';

import 'package:riverpod/legacy.dart';

import '../../../providers/ndk_provider.dart';

final restoreStateProvider =
    StateNotifierProvider<RestoreNotifier, RestoreState>((ref) {
      final ndk = ref.read(ndkProvider);
      return RestoreNotifier(ndk: ndk);
    });

class RestoreState {
  final bool isRestoring;
  final bool isComplete;

  /// Accumulated restored amount keyed by unit (e.g. 'sat', 'eur').
  final Map<String, int> restoredAmountByUnit;
  final int totalProofCount;
  final int currentCounter;

  /// The unit currently being restored.
  final String? restoringUnit;

  /// All units queued for this restore session.
  final List<String> pendingUnits;
  final String? error;

  const RestoreState({
    this.isRestoring = false,
    this.isComplete = false,
    this.restoredAmountByUnit = const {},
    this.totalProofCount = 0,
    this.currentCounter = 0,
    this.restoringUnit,
    this.pendingUnits = const [],
    this.error,
  });

  RestoreState copyWith({
    bool? isRestoring,
    bool? isComplete,
    Map<String, int>? restoredAmountByUnit,
    int? totalProofCount,
    int? currentCounter,
    String? restoringUnit,
    bool clearRestoringUnit = false,
    List<String>? pendingUnits,
    String? error,
  }) {
    return RestoreState(
      isRestoring: isRestoring ?? this.isRestoring,
      isComplete: isComplete ?? this.isComplete,
      restoredAmountByUnit: restoredAmountByUnit ?? this.restoredAmountByUnit,
      totalProofCount: totalProofCount ?? this.totalProofCount,
      currentCounter: currentCounter ?? this.currentCounter,
      restoringUnit: clearRestoringUnit
          ? null
          : (restoringUnit ?? this.restoringUnit),
      pendingUnits: pendingUnits ?? this.pendingUnits,
      error: error,
    );
  }
}

class RestoreNotifier extends StateNotifier<RestoreState> {
  final Ndk ndk;
  StreamSubscription? _restoreSubscription;
  String _currentUnit = '';

  RestoreNotifier({required this.ndk}) : super(const RestoreState());

  /// Restores all [units] sequentially from the given [mintUrl].
  Future<void> startRestoreAllUnits({
    required String mintUrl,
    required List<String> units,
  }) async {
    await _restoreSubscription?.cancel();
    state = RestoreState(
      isRestoring: true,
      pendingUnits: List.unmodifiable(units),
    );

    ndk.cashu.addMintToKnownMints(mintUrl: mintUrl);

    for (final unit in units) {
      if (!state.isRestoring) break;
      state = state.copyWith(restoringUnit: unit, currentCounter: 0);
      await _restoreSingleUnit(mintUrl: mintUrl, unit: unit);
      if (state.error != null) break;
    }

    if (state.isRestoring) {
      state = state.copyWith(
        isRestoring: false,
        isComplete: true,
        clearRestoringUnit: true,
      );
    }
  }

  Future<void> _restoreSingleUnit({
    required String mintUrl,
    required String unit,
    int startCounter = 0,
    int batchSize = 100,
    int gapLimit = 16,
  }) async {
    _currentUnit = unit;
    final completer = Completer<void>();
    try {
      final restoreStream = ndk.cashu.restore(
        mintUrl: mintUrl,
        unit: unit,
        startCounter: startCounter,
        batchSize: batchSize,
        gapLimit: gapLimit,
      );
      _restoreSubscription = restoreStream.listen(
        (result) => _handleRestoreResult(result),
        onError: (error) {
          state = state.copyWith(error: error.toString());
          if (!completer.isCompleted) completer.complete();
        },
        onDone: () {
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      if (!completer.isCompleted) completer.complete();
    }
    await completer.future;
  }

  void _handleRestoreResult(CashuRestoreResult result) {
    var batchAmount = 0;
    var maxCounter = 0;

    for (var keysetResult in result.keysetResults) {
      for (var proof in keysetResult.restoredProofs) {
        batchAmount += proof.amount;
      }
      if (keysetResult.lastUsedCounter > maxCounter) {
        maxCounter = keysetResult.lastUsedCounter;
      }
    }

    final updatedAmounts = Map<String, int>.from(state.restoredAmountByUnit);
    updatedAmounts[_currentUnit] =
        (updatedAmounts[_currentUnit] ?? 0) + batchAmount;

    state = state.copyWith(
      restoredAmountByUnit: updatedAmounts,
      totalProofCount: state.totalProofCount + result.totalProofsRestored,
      currentCounter: maxCounter,
    );
  }

  void reset() {
    _restoreSubscription?.cancel();
    state = const RestoreState();
  }

  @override
  void dispose() {
    _restoreSubscription?.cancel();
    super.dispose();
  }
}
