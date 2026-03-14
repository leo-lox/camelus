import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod/riverpod.dart';

class QRScannerState {
  final bool isProcessing;
  final String? error;
  final QRNavigationTarget? navigationTarget;
  final Map<String, dynamic>? navigationData;

  QRScannerState({
    required this.isProcessing,
    required this.error,
    required this.navigationTarget,
    required this.navigationData,
  });

  QRScannerState copyWith({
    bool? isProcessing,
    String? error,
    QRNavigationTarget? navigationTarget,
    Map<String, dynamic>? navigationData,
  }) {
    return QRScannerState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      navigationTarget: navigationTarget ?? this.navigationTarget,
      navigationData: navigationData ?? this.navigationData,
    );
  }
}

enum QRNavigationTarget { rcvPage, sendPage }

class QRScanTypeResult {
  final String value;
  final QRScanTypes type;

  QRScanTypeResult({required this.value, required this.type});
}

enum QRScanTypes { cashuToken, lightningInvoice, unknown }

class QRScannerNotifier extends StateNotifier<QRScannerState> {
  QRScannerNotifier()
    : super(
        QRScannerState(
          isProcessing: false,
          error: null,
          navigationTarget: null,
          navigationData: null,
        ),
      );

  void setError(String error) {
    state = state.copyWith(error: error);
  }

  Future<void> processQRCode(String qrData) async {
    state = state.copyWith(isProcessing: true, error: null);

    final result = await _analyzeQRData(qrData);

    if (result.type == QRScanTypes.cashuToken) {
      state = state.copyWith(
        isProcessing: false,
        navigationTarget: QRNavigationTarget.rcvPage,
        navigationData: {'cashuTokenString': result.value},
      );
    } else if (result.type == QRScanTypes.lightningInvoice) {
      state = state.copyWith(
        isProcessing: false,
        navigationTarget: QRNavigationTarget.sendPage,
        navigationData: {'lightningInvoice': result.value},
      );
    } else {
      state = state.copyWith(
        isProcessing: false,
        error: 'Unsupported QR code type',
      );
    }
  }

  void clearNavigation() {
    state = state.copyWith(navigationTarget: null, navigationData: null);
  }

  void reset() {
    state = state.copyWith(
      isProcessing: false,
      error: null,
      navigationTarget: null,
      navigationData: null,
    );
  }

  Future<QRScanTypeResult> _analyzeQRData(String qrData) async {
    // Analyze the QR data and return the appropriate type
    if (qrData.startsWith('cashuB')) {
      return QRScanTypeResult(value: qrData, type: QRScanTypes.cashuToken);
    } else if (qrData.startsWith('lightning:')) {
      return QRScanTypeResult(
        value: qrData,
        type: QRScanTypes.lightningInvoice,
      );
    }
    return QRScanTypeResult(value: qrData, type: QRScanTypes.unknown);
  }
}

final qrScannerProvider =
    StateNotifierProvider.autoDispose<QRScannerNotifier, QRScannerState>(
      (ref) => QRScannerNotifier(),
    );
