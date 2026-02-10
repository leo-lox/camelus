import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Service for managing WebRTC peer connections
class VoiceWebRTCService {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final Map<String, MediaStream> _remoteStreams = {};

  final _connectionStateController =
      StreamController<RTCPeerConnectionState>.broadcast();
  final _iceStateController =
      StreamController<RTCIceConnectionState>.broadcast();
  final _remoteStreamController = StreamController<MediaStream>.broadcast();

  Stream<RTCPeerConnectionState> get connectionState =>
      _connectionStateController.stream;
  Stream<RTCIceConnectionState> get iceConnectionState =>
      _iceStateController.stream;
  Stream<MediaStream> get remoteStreams => _remoteStreamController.stream;

  bool get isInitialized => _localStream != null;
  bool get isConnected => _peerConnection != null;

  /// Initialize local audio stream
  Future<void> initialize() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'sampleRate': 48000,
      },
      'video': false,
    });
  }

  /// Create peer connection and add local track
  Future<RTCPeerConnection> createPeerConnectionLocal({
    required List<String> stunServers,
    List<String>? turnServers,
    String? turnUsername,
    String? turnPassword,
  }) async {
    final configuration = {
      'iceServers': [
        {'urls': stunServers},
        if (turnServers != null && turnServers.isNotEmpty)
          {
            'urls': turnServers,
            'username': turnUsername,
            'credential': turnPassword,
          },
      ],
      'sdpSemantics': 'unified-plan',
    };

    _peerConnection = await createPeerConnection(configuration);

    // Add local audio track
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        await _peerConnection!.addTrack(track, _localStream!);
      }
    }

    // Handle remote tracks
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        final stream = event.streams.first;
        _remoteStreams[stream.id] = stream;
        _remoteStreamController.add(stream);
      }
    };

    // Handle ICE candidates
    _peerConnection!.onIceCandidate = (candidate) {
      // Will be sent via signaling service
      _onIceCandidateCallback?.call(candidate);
    };

    // Handle connection state changes
    _peerConnection!.onConnectionState = (state) {
      _connectionStateController.add(state);
    };

    _peerConnection!.onIceConnectionState = (state) {
      _iceStateController.add(state);
    };

    return _peerConnection!;
  }

  // Callback for ICE candidates
  void Function(RTCIceCandidate)? _onIceCandidateCallback;

  void setOnIceCandidate(void Function(RTCIceCandidate) callback) {
    _onIceCandidateCallback = callback;
  }

  /// Create WebRTC offer
  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) {
      throw StateError('Peer connection not created');
    }

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    return offer;
  }

  /// Set remote answer
  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null) {
      throw StateError('Peer connection not created');
    }

    await _peerConnection!.setRemoteDescription(answer);
  }

  /// Add ICE candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) {
      throw StateError('Peer connection not created');
    }

    await _peerConnection!.addCandidate(candidate);
  }

  /// Toggle mute
  Future<void> setMuted(bool muted) async {
    if (_localStream == null) return;

    for (final track in _localStream!.getAudioTracks()) {
      print("Setting track ${track.id} enabled=${!muted} NOT IMPLEMENTED");
      //await track.setEnabled(!muted);
    }
  }

  /// Check if muted
  bool get isMuted {
    if (_localStream == null) return false;
    final tracks = _localStream!.getAudioTracks();
    if (tracks.isEmpty) return false;
    return !tracks.first.enabled;
  }

  /// Disconnect and cleanup
  Future<void> disconnect() async {
    await _peerConnection?.close();
    _peerConnection = null;

    await _localStream?.dispose();
    _localStream = null;

    for (final stream in _remoteStreams.values) {
      await stream.dispose();
    }
    _remoteStreams.clear();
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _iceStateController.close();
    _remoteStreamController.close();
  }
}
