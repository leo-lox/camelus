import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../../domain_layer/usecases/voice/livekit_voice_service.dart';

/// Provider for LiveKit voice service
final liveKitVoiceServiceProvider = Provider.autoDispose<LiveKitVoiceService>((
  ref,
) {
  final service = LiveKitVoiceService();

  // Cleanup when disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// State for active voice connection
class VoiceConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final bool isMuted;
  final String? currentRoomId;
  final String? currentServerUrl;
  final String? error;
  final int participantCount;

  VoiceConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.isMuted = false,
    this.currentRoomId,
    this.currentServerUrl,
    this.error,
    this.participantCount = 0,
  });

  VoiceConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    bool? isMuted,
    String? currentRoomId,
    String? currentServerUrl,
    String? error,
    int? participantCount,
  }) {
    return VoiceConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      isMuted: isMuted ?? this.isMuted,
      currentRoomId: currentRoomId ?? this.currentRoomId,
      currentServerUrl: currentServerUrl ?? this.currentServerUrl,
      error: error,
      participantCount: participantCount ?? this.participantCount,
    );
  }
}

/// Provider for voice connection state
final voiceConnectionProvider =
    StateNotifierProvider<VoiceConnectionNotifier, VoiceConnectionState>((ref) {
      return VoiceConnectionNotifier();
    });

class VoiceConnectionNotifier extends StateNotifier<VoiceConnectionState> {
  VoiceConnectionNotifier() : super(VoiceConnectionState());

  void setConnecting(bool connecting) {
    state = state.copyWith(isConnecting: connecting);
  }

  void setConnected(bool connected, {String? roomId, String? serverUrl}) {
    state = state.copyWith(
      isConnected: connected,
      isConnecting: false,
      currentRoomId: roomId,
      currentServerUrl: serverUrl,
      error: null,
    );
  }

  void setMuted(bool muted) {
    state = state.copyWith(isMuted: muted);
  }

  void setError(String error) {
    state = state.copyWith(
      error: error,
      isConnecting: false,
      isConnected: false,
    );
  }

  void setParticipantCount(int count) {
    state = state.copyWith(participantCount: count);
  }

  void disconnect() {
    state = VoiceConnectionState();
  }
}
