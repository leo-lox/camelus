import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings for animated QR code display and scanning
class QrSettings {
  /// Frame delay in milliseconds for animated QR codes
  final int frameDelayMs;

  /// Maximum fragment length for UR encoding (affects QR density)
  /// Lower values = more frames, simpler QR codes
  /// Higher values = fewer frames, denser QR codes
  final int maxFragmentLen;

  const QrSettings({required this.frameDelayMs, required this.maxFragmentLen});

  QrSettings copyWith({int? frameDelayMs, int? maxFragmentLen}) {
    return QrSettings(
      frameDelayMs: frameDelayMs ?? this.frameDelayMs,
      maxFragmentLen: maxFragmentLen ?? this.maxFragmentLen,
    );
  }
}

class QrSettingsNotifier extends Notifier<QrSettings> {
  @override
  QrSettings build() =>
      const QrSettings(frameDelayMs: 300, maxFragmentLen: 100);

  void setFrameDelay(int delayMs) {
    state = state.copyWith(frameDelayMs: delayMs);
  }

  void setMaxFragmentLen(int length) {
    state = state.copyWith(maxFragmentLen: length);
  }

  void updateSettings({int? frameDelayMs, int? maxFragmentLen}) {
    state = state.copyWith(
      frameDelayMs: frameDelayMs,
      maxFragmentLen: maxFragmentLen,
    );
  }
}

final qrSettingsProvider = NotifierProvider<QrSettingsNotifier, QrSettings>(
  QrSettingsNotifier.new,
);
