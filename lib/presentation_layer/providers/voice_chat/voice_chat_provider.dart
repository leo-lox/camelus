import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../domain_layer/entities/voice_chat/channel_state.dart';
import '../../../domain_layer/entities/voice_chat/voice_channel.dart';
import '../../../domain_layer/entities/voice_chat/voice_user.dart';
import '../../../domain_layer/entities/voice_chat/user_group.dart';

enum ConnectionStatus { disconnected, connecting, connected, error }

class VoiceChatState {
  final ChannelState channelState;
  final ConnectionStatus connectionStatus;
  final String? serverUrl;
  final String? error;
  final DateTime? lastPingTime;
  final int? pingLatencyMs;
  final int reconnectAttempts;

  VoiceChatState({
    required this.channelState,
    this.connectionStatus = ConnectionStatus.disconnected,
    this.serverUrl,
    this.error,
    this.lastPingTime,
    this.pingLatencyMs,
    this.reconnectAttempts = 0,
  });

  bool get isConnected => connectionStatus == ConnectionStatus.connected;

  VoiceChatState copyWith({
    ChannelState? channelState,
    ConnectionStatus? connectionStatus,
    String? serverUrl,
    String? error,
    DateTime? lastPingTime,
    int? pingLatencyMs,
    int? reconnectAttempts,
  }) {
    return VoiceChatState(
      channelState: channelState ?? this.channelState,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      serverUrl: serverUrl ?? this.serverUrl,
      error: error,
      lastPingTime: lastPingTime ?? this.lastPingTime,
      pingLatencyMs: pingLatencyMs ?? this.pingLatencyMs,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
    );
  }
}

class VoiceChatNotifier extends Notifier<VoiceChatState> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  @override
  VoiceChatState build() {
    ref.onDispose(() {
      _cleanup();
    });
    return VoiceChatState(channelState: ChannelState());
  }

  void _cleanup() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
  }

  Future<void> connect(String serverUrl, String? npub) async {
    try {
      // Disconnect if already connected
      await disconnect();

      state = state.copyWith(
        connectionStatus: ConnectionStatus.connecting,
        serverUrl: serverUrl,
        error: null,
      );

      // Connect to WebSocket server
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);

      // Send authentication message
      final authMessage = {
        'type': 'auth',
        'npub': npub,
      };
      _channel!.sink.add(jsonEncode(authMessage));

      // Listen to messages
      _subscription = _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          state = state.copyWith(
            error: 'Connection error: $error',
            connectionStatus: ConnectionStatus.error,
          );
          _schedulereconnect(serverUrl, npub);
        },
        onDone: () {
          state = state.copyWith(connectionStatus: ConnectionStatus.disconnected);
          _schedulereconnect(serverUrl, npub);
        },
      );

      state = state.copyWith(
        connectionStatus: ConnectionStatus.connected,
        error: null,
        reconnectAttempts: 0,
      );

      // Start ping timer
      _startPingTimer();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to connect: $e',
        connectionStatus: ConnectionStatus.error,
      );
    }
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (state.isConnected && _channel != null) {
        final pingTime = DateTime.now();
        final message = {
          'type': 'ping',
          'timestamp': pingTime.millisecondsSinceEpoch,
        };
        try {
          _channel!.sink.add(jsonEncode(message));
        } catch (e) {
          // Connection might be dead
          state = state.copyWith(connectionStatus: ConnectionStatus.error);
        }
      }
    });
  }

  void _schedulereconnect(String serverUrl, String? npub) {
    if (state.reconnectAttempts >= 5) {
      state = state.copyWith(
        error: 'Max reconnection attempts reached',
        connectionStatus: ConnectionStatus.error,
      );
      return;
    }

    final delay = Duration(seconds: (state.reconnectAttempts + 1) * 2);
    state = state.copyWith(reconnectAttempts: state.reconnectAttempts + 1);

    Timer(delay, () {
      if (state.connectionStatus != ConnectionStatus.connected) {
        connect(serverUrl, npub);
      }
    });
  }

  Future<void> disconnect() async {
    _pingTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _pingTimer = null;
    _subscription = null;
    _channel = null;

    state = state.copyWith(
      connectionStatus: ConnectionStatus.disconnected,
      serverUrl: null,
      reconnectAttempts: 0,
    );
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'] as String?;

      switch (type) {
        case 'state':
          _handleStateUpdate(data);
          break;
        case 'user_joined':
          _handleUserJoined(data);
          break;
        case 'user_left':
          _handleUserLeft(data);
          break;
        case 'user_speaking':
          _handleUserSpeaking(data);
          break;
        case 'user_moved':
          _handleUserMoved(data);
          break;
        case 'pong':
          _handlePong(data);
          break;
        case 'error':
          state = state.copyWith(error: data['message'] as String?);
          break;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to parse message: $e');
    }
  }

  void _handlePong(Map<String, dynamic> data) {
    final timestamp = data['timestamp'] as int?;
    if (timestamp != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final latency = now - timestamp;
      state = state.copyWith(
        lastPingTime: DateTime.now(),
        pingLatencyMs: latency,
      );
    }
  }

  void _handleStateUpdate(Map<String, dynamic> data) {
    try {
      final stateData = data['data'] as Map<String, dynamic>?;
      if (stateData == null) {
        state = state.copyWith(error: 'Invalid state update: missing data field');
        return;
      }

      final channelsData = stateData['channels'] as List<dynamic>?;
      final usersData = stateData['users'] as List<dynamic>?;

      final channels = channelsData?.map((c) {
            return VoiceChannel(
              id: c['id'] as String,
              name: c['name'] as String,
              parentId: c['parent_id'] as String?,
              position: c['position'] as int,
              userIds: (c['user_ids'] as List<dynamic>?)
                      ?.map((id) => id as String)
                      .toList() ??
                  [],
            );
          }).toList() ??
          [];

      final users = usersData?.map((u) {
            return VoiceUser(
              id: u['id'] as String,
              npub: u['npub'] as String?,
              displayName: u['display_name'] as String?,
              group: UserGroup.fromString(u['group'] as String? ?? 'anon'),
              channelId: u['channel_id'] as String?,
              isSpeaking: u['is_speaking'] as bool? ?? false,
              isMuted: u['is_muted'] as bool? ?? false,
            );
          }).toList() ??
          [];

      state = state.copyWith(
        channelState: state.channelState.copyWith(
          channels: channels,
          users: users,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to parse state update: $e');
    }
  }

  void _handleUserJoined(Map<String, dynamic> data) {
    final userData = data['user'] as Map<String, dynamic>?;
    if (userData == null) return;

    final newUser = VoiceUser(
      id: userData['id'] as String,
      npub: userData['npub'] as String?,
      displayName: userData['display_name'] as String?,
      group: UserGroup.fromString(userData['group'] as String? ?? 'anon'),
      channelId: userData['channel_id'] as String?,
      isSpeaking: userData['is_speaking'] as bool? ?? false,
      isMuted: userData['is_muted'] as bool? ?? false,
    );

    final updatedUsers = [...state.channelState.users, newUser];
    state = state.copyWith(
      channelState: state.channelState.copyWith(users: updatedUsers),
    );
  }

  void _handleUserLeft(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    if (userId == null) return;

    final updatedUsers =
        state.channelState.users.where((u) => u.id != userId).toList();
    state = state.copyWith(
      channelState: state.channelState.copyWith(users: updatedUsers),
    );
  }

  void _handleUserSpeaking(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    final isSpeaking = data['is_speaking'] as bool?;
    if (userId == null || isSpeaking == null) return;

    final updatedUsers = state.channelState.users.map((u) {
      if (u.id == userId) {
        return u.copyWith(isSpeaking: isSpeaking);
      }
      return u;
    }).toList();

    state = state.copyWith(
      channelState: state.channelState.copyWith(users: updatedUsers),
    );
  }

  void _handleUserMoved(Map<String, dynamic> data) {
    final userId = data['user_id'] as String?;
    final channelId = data['channel_id'] as String?;
    if (userId == null) return;

    final updatedUsers = state.channelState.users.map((u) {
      if (u.id == userId) {
        return u.copyWith(channelId: channelId);
      }
      return u;
    }).toList();

    state = state.copyWith(
      channelState: state.channelState.copyWith(users: updatedUsers),
    );
  }

  void joinChannel(String channelId) {
    if (!state.isConnected || _channel == null) return;

    final message = {
      'type': 'join_channel',
      'channel_id': channelId,
    };
    _channel!.sink.add(jsonEncode(message));

    state = state.copyWith(
      channelState: state.channelState.copyWith(currentChannelId: channelId),
    );
  }

  void toggleMute() {
    if (!state.isConnected || _channel == null) return;

    final currentUser = state.channelState.users.firstWhere(
      (u) => u.id == state.channelState.currentUserId,
      orElse: () => VoiceUser(id: '', group: UserGroup.anon),
    );

    final message = {
      'type': 'toggle_mute',
      'muted': !currentUser.isMuted,
    };
    _channel!.sink.add(jsonEncode(message));
  }

}

final voiceChatProvider =
    NotifierProvider<VoiceChatNotifier, VoiceChatState>(VoiceChatNotifier.new);
