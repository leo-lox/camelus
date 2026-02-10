import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service for managing LiveKit voice connections
class LiveKitVoiceService {
  Room? _room;
  LocalAudioTrack? _localAudioTrack;
  
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  final _participantsController = StreamController<List<Participant>>.broadcast();
  
  bool _isMuted = false;
  bool _isConnected = false;
  
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<List<Participant>> get participantsStream => _participantsController.stream;
  
  bool get isMuted => _isMuted;
  bool get isConnected => _isConnected;
  List<Participant> get participants => _room?.remoteParticipants.values.toList() ?? [];

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Connect to a LiveKit room
  Future<void> connect({
    required String url,
    required String token,
    required String roomName,
  }) async {
    try {
      // Request microphone permission
      final hasPermission = await requestMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      // Create room
      _room = Room();

      // Set up event listeners
      _room!.addListener(_onRoomUpdate);
      
      // Connect to room
      await _room!.connect(
        url,
        token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      // Publish local audio track
      await _publishAudio();
      
      _isConnected = true;
      _connectionStateController.add(_room!.connectionState);
      _updateParticipants();
      
      debugPrint('Connected to LiveKit room: $roomName');
    } catch (e) {
      debugPrint('Failed to connect to LiveKit: $e');
      rethrow;
    }
  }

  Future<void> _publishAudio() async {
    try {
      // Create audio track
      _localAudioTrack = await LocalAudioTrack.create(AudioCaptureOptions(
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
      ));

      // Publish track
      await _room!.localParticipant?.publishAudioTrack(_localAudioTrack!);
      
      debugPrint('Published local audio track');
    } catch (e) {
      debugPrint('Failed to publish audio: $e');
      rethrow;
    }
  }

  void _onRoomUpdate() {
    if (_room == null) return;
    
    _connectionStateController.add(_room!.connectionState);
    _updateParticipants();
  }

  void _updateParticipants() {
    if (_room == null) return;
    
    final participants = [
      if (_room!.localParticipant != null) _room!.localParticipant!,
      ..._room!.remoteParticipants.values,
    ];
    
    _participantsController.add(participants);
  }

  /// Toggle mute/unmute
  Future<void> toggleMute() async {
    if (_localAudioTrack == null) return;
    
    _isMuted = !_isMuted;
    await _localAudioTrack!.mute(_isMuted);
    
    debugPrint('Audio ${_isMuted ? 'muted' : 'unmuted'}');
  }

  /// Disconnect from the room
  Future<void> disconnect() async {
    try {
      // Stop local track
      if (_localAudioTrack != null) {
        await _localAudioTrack!.stop();
        _localAudioTrack = null;
      }

      // Disconnect room
      if (_room != null) {
        _room!.removeListener(_onRoomUpdate);
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }

      _isConnected = false;
      _isMuted = false;
      
      debugPrint('Disconnected from LiveKit room');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _participantsController.close();
  }
}
