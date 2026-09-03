import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/entities.dart';
import 'package:ur/cashu_token_ur_encoder.dart';
import 'package:ur/ur_decoder.dart';

/// State for the animated QR scanner
class AnimatedQrScannerState {
  final bool isScanning;
  final double progress;
  final CashuToken? completedToken;
  final String? error;
  final int partsReceived;
  final int? estimatedTotalParts;

  const AnimatedQrScannerState({
    required this.isScanning,
    required this.progress,
    this.completedToken,
    this.error,
    required this.partsReceived,
    this.estimatedTotalParts,
  });

  AnimatedQrScannerState copyWith({
    bool? isScanning,
    double? progress,
    CashuToken? completedToken,
    String? error,
    int? partsReceived,
    int? estimatedTotalParts,
  }) {
    return AnimatedQrScannerState(
      isScanning: isScanning ?? this.isScanning,
      progress: progress ?? this.progress,
      completedToken: completedToken ?? this.completedToken,
      error: error ?? this.error,
      partsReceived: partsReceived ?? this.partsReceived,
      estimatedTotalParts: estimatedTotalParts ?? this.estimatedTotalParts,
    );
  }

  static AnimatedQrScannerState initial() {
    return const AnimatedQrScannerState(
      isScanning: false,
      progress: 0.0,
      partsReceived: 0,
    );
  }
}

/// Notifier for managing animated QR code scanning
class AnimatedQrScannerNotifier extends Notifier<AnimatedQrScannerState> {
  URDecoder? _decoder;

  @override
  AnimatedQrScannerState build() {
    _decoder = null;
    return AnimatedQrScannerState.initial();
  }

  /// Process a scanned QR code part.
  /// Returns true if this completed the token.
  Future<bool> processPart(String urPart) async {
    try {
      // If not scanning yet, try single-part first
      if (!state.isScanning && state.completedToken == null) {
        final token = CashuTokenUrEncoder.decodeSinglePart(urPart);
        if (token != null) {
          state = state.copyWith(
            completedToken: token,
            progress: 1.0,
            partsReceived: 1,
            estimatedTotalParts: 1,
          );
          return true;
        }

        // Start multi-part scanning
        _decoder = CashuTokenUrEncoder.createMultiPartDecoder();
        state = state.copyWith(
          isScanning: true,
          partsReceived: 0,
          progress: 0.0,
        );
      }

      // Feed part to decoder
      if (_decoder != null) {
        _decoder!.receivePart(urPart);

        final partsReceived = state.partsReceived + 1;
        final progress = _decoder!.estimatedPercentComplete();

        state = state.copyWith(
          partsReceived: partsReceived,
          progress: progress,
        );

        // Check if complete
        if (_decoder!.isComplete()) {
          if (_decoder!.isSuccess()) {
            final token = CashuTokenUrEncoder.decodeFromMultiPartDecoder(
              _decoder!,
            );

            if (token != null) {
              state = state.copyWith(
                completedToken: token,
                progress: 1.0,
                isScanning: false,
              );
              return true;
            } else {
              state = state.copyWith(
                error: 'Failed to decode token',
                isScanning: false,
              );
            }
          } else {
            state = state.copyWith(
              error: 'Decoder reported failure',
              isScanning: false,
            );
          }
        }
      }

      return false;
    } catch (e) {
      state = state.copyWith(
        error: 'Error processing QR part: $e',
        isScanning: false,
      );
      return false;
    }
  }

  /// Reset the scanner
  void reset() {
    _decoder = null;
    state = AnimatedQrScannerState.initial();
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for animated QR scanner state
final animatedQrScannerProvider =
    NotifierProvider.autoDispose<
      AnimatedQrScannerNotifier,
      AnimatedQrScannerState
    >(AnimatedQrScannerNotifier.new);

/// Widget to display multi-part UR scanning progress
class AnimatedQrScanProgress extends ConsumerWidget {
  const AnimatedQrScanProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(animatedQrScannerProvider);

    if (!scannerState.isScanning && scannerState.completedToken == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scannerState.completedToken != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Token Received!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ] else if (scannerState.isScanning) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    value: scannerState.progress,
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'keep scanning: ${(scannerState.progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: scannerState.progress,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text(
              '${scannerState.partsReceived} parts received',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (scannerState.error != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    scannerState.error!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
