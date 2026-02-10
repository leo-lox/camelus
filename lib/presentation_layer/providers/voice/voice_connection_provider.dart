import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../domain_layer/entities/voice/voice_server.dart';
import '../../../services/voice/voice_signaling_service.dart';
import '../../../services/voice/voice_webrtc_service.dart';
import '../ndk_provider.dart';
import 'voice_servers_provider.dart';

/// Voice connection state
enum VoiceConnectionState {
  disconnected,
  initializing,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Voice connection data
class VoiceConnectionData {
  final VoiceConnectionState state;
  final VoiceServer? server;
  final String? channelId;
  final String? error;
  final RTCIceConnectionState? iceState;

  const VoiceConnectionData({
    required this.state,
    this.server,
    this.channelId,
    this.error,
    this.iceState,
  });

  VoiceConnectionData copyWith({
    VoiceConnectionState? state,
    VoiceServer? server,
    String? channelId,
    String? error,
    RTCIceConnectionState? iceState,
  }) {
    return VoiceConnectionData(
      state: state ?? this.state,
      server: server ?? this.server,
      channelId: channelId ?? this.channelId,
      error: error ?? this.error,
      iceState: iceState ?? this.iceState,
    );
  }
}

/// Provider for voice connection state
final voiceConnectionProvider =
    StateNotifierProvider<VoiceConnectionNotifier, VoiceConnectionData>((ref) {
      return VoiceConnectionNotifier(ref);
    });

class VoiceConnectionNotifier extends StateNotifier<VoiceConnectionData> {
  final Ref ref;
  VoiceWebRTCService? _webrtcService;
  VoiceSignalingService? _signalingService;
  StreamSubscription? _answerSubscription;
  StreamSubscription? _iceCandidateSubscription;
  StreamSubscription? _iceStateSubscription;

  VoiceConnectionNotifier(this.ref)
    : super(
        const VoiceConnectionData(state: VoiceConnectionState.disconnected),
      );

  /// Connect to a voice server
  Future<void> connect(VoiceServer server, {String channelId = 'lobby'}) async {
    try {
      state = state.copyWith(
        state: VoiceConnectionState.initializing,
        server: server,
        channelId: channelId,
      );

      // Initialize WebRTC service
      _webrtcService = VoiceWebRTCService();
      await _webrtcService!.initialize();

      // Create signaling service
      final ndk = ref.read(ndkProvider);
      _signalingService = VoiceSignalingService(
        ndk: ndk,
        serverPubkey: server.pubkey,
      );

      state = state.copyWith(state: VoiceConnectionState.connecting);

      // Listen for answer before sending offer
      _answerSubscription = _signalingService!.listenForAnswer().listen(
        (answer) async {
          await _webrtcService!.setRemoteAnswer(answer);
        },
        onError: (e) {
          state = state.copyWith(
            state: VoiceConnectionState.error,
            error: 'Failed to receive answer: $e',
          );
        },
      );

      // Listen for ICE candidates
      _iceCandidateSubscription = _signalingService!
          .listenForIceCandidates()
          .listen(
            (candidate) async {
              await _webrtcService!.addIceCandidate(candidate);
            },
            onError: (e) {
              // Log error but don't disconnect
            },
          );

      // Create peer connection
      await _webrtcService!.createPeerConnectionLocal(
        stunServers: server.stunServers,
        turnServers: server.turnServers.isNotEmpty ? server.turnServers : null,
      );

      // Set ICE candidate callback
      _webrtcService!.setOnIceCandidate((candidate) {
        _signalingService!.sendIceCandidate(candidate);
      });

      // Monitor ICE state
      _iceStateSubscription = _webrtcService!.iceConnectionState.listen((
        iceState,
      ) {
        state = state.copyWith(iceState: iceState);

        if (iceState == RTCIceConnectionState.RTCIceConnectionStateConnected) {
          state = state.copyWith(state: VoiceConnectionState.connected);
        } else if (iceState ==
                RTCIceConnectionState.RTCIceConnectionStateFailed ||
            iceState == RTCIceConnectionState.RTCIceConnectionStateClosed) {
          disconnect();
        }
      });

      // Create and send offer
      final offer = await _webrtcService!.createOffer();

      // Get username from signer

      final username = ref
          .read(ndkProvider)
          .accounts
          .getPublicKey()!
          .substring(0, 8);

      await _signalingService!.sendOffer(
        offer,
        username: username,
        channelId: channelId,
      );
    } catch (e) {
      state = state.copyWith(
        state: VoiceConnectionState.error,
        error: e.toString(),
      );
    }
  }

  /// Disconnect from voice server
  Future<void> disconnect() async {
    state = state.copyWith(state: VoiceConnectionState.disconnecting);

    await _answerSubscription?.cancel();
    await _iceCandidateSubscription?.cancel();
    await _iceStateSubscription?.cancel();

    await _webrtcService?.disconnect();
    _webrtcService = null;
    _signalingService = null;

    state = const VoiceConnectionData(state: VoiceConnectionState.disconnected);
  }

  /// Toggle mute
  Future<void> toggleMute() async {
    if (_webrtcService == null) return;
    await _webrtcService!.setMuted(!_webrtcService!.isMuted);
  }

  /// Get mute state
  bool get isMuted => _webrtcService?.isMuted ?? false;

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

/// Provider for mute state
final isMutedProvider = Provider<bool>((ref) {
  final connection = ref.watch(voiceConnectionProvider.notifier);
  return connection.isMuted;
});

/// Provider for deafen state (for future implementation)
final isDeafenedProvider = StateProvider<bool>((ref) => false);
