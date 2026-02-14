import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCState {
  final RTCPeerConnection? peerConnection;
  final MediaStream? localStream;
  final bool isMuted;
  final bool isConnected;
  final String? error;

  WebRTCState({
    this.peerConnection,
    this.localStream,
    this.isMuted = false,
    this.isConnected = false,
    this.error,
  });

  WebRTCState copyWith({
    RTCPeerConnection? peerConnection,
    MediaStream? localStream,
    bool? isMuted,
    bool? isConnected,
    String? error,
  }) {
    return WebRTCState(
      peerConnection: peerConnection ?? this.peerConnection,
      localStream: localStream ?? this.localStream,
      isMuted: isMuted ?? this.isMuted,
      isConnected: isConnected ?? this.isConnected,
      error: error,
    );
  }
}

class WebRTCNotifier extends Notifier<WebRTCState> {
  @override
  WebRTCState build() {
    ref.onDispose(() {
      _cleanup();
    });
    return WebRTCState();
  }

  Future<void> _cleanup() async {
    await state.localStream?.dispose();
    await state.peerConnection?.close();
  }

  Future<void> initializeLocalStream() async {
    try {
      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': false,
      };

      final stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      state = state.copyWith(localStream: stream);
    } catch (e) {
      state = state.copyWith(error: 'Failed to get media: $e');
    }
  }

  Future<void> initializePeerConnection(
    Map<String, dynamic> configuration,
  ) async {
    try {
      final pc = await createPeerConnection(configuration);

      pc.onIceCandidate = (RTCIceCandidate candidate) {
        // Send ICE candidate to signaling server
        // This will be handled by the voice chat provider
      };

      pc.onIceConnectionState = (RTCIceConnectionState state) {
        this.state = this.state.copyWith(
          isConnected: state == RTCIceConnectionState.RTCIceConnectionStateConnected,
        );
      };

      pc.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          // Handle remote audio stream
        }
      };

      // Add local stream to peer connection
      if (state.localStream != null) {
        state.localStream!.getTracks().forEach((track) {
          pc.addTrack(track, state.localStream!);
        });
      }

      state = state.copyWith(peerConnection: pc);
    } catch (e) {
      state = state.copyWith(error: 'Failed to create peer connection: $e');
    }
  }

  Future<RTCSessionDescription?> createOffer() async {
    try {
      if (state.peerConnection == null) return null;

      final offer = await state.peerConnection!.createOffer();
      await state.peerConnection!.setLocalDescription(offer);
      return offer;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create offer: $e');
      return null;
    }
  }

  Future<RTCSessionDescription?> createAnswer() async {
    try {
      if (state.peerConnection == null) return null;

      final answer = await state.peerConnection!.createAnswer();
      await state.peerConnection!.setLocalDescription(answer);
      return answer;
    } catch (e) {
      state = state.copyWith(error: 'Failed to create answer: $e');
      return null;
    }
  }

  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      if (state.peerConnection == null) return;
      await state.peerConnection!.setRemoteDescription(description);
    } catch (e) {
      state = state.copyWith(error: 'Failed to set remote description: $e');
    }
  }

  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      if (state.peerConnection == null) return;
      await state.peerConnection!.addCandidate(candidate);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add ICE candidate: $e');
    }
  }

  void toggleMute() {
    if (state.localStream == null) return;

    final audioTracks = state.localStream!.getAudioTracks();
    final newMutedState = !state.isMuted;
    
    for (var track in audioTracks) {
      // When muted (true), tracks should be disabled (false)
      // When unmuted (false), tracks should be enabled (true)
      track.enabled = !newMutedState;
    }

    state = state.copyWith(isMuted: newMutedState);
  }
}

final webRTCProvider = NotifierProvider<WebRTCNotifier, WebRTCState>(
  WebRTCNotifier.new,
);
