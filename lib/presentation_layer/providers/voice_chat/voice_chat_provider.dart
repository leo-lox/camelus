import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../domain_layer/entities/voice_chat/channel_state.dart';
import '../../../domain_layer/entities/voice_chat/voice_channel.dart';
import '../../../domain_layer/entities/voice_chat/voice_user.dart';
import '../../../domain_layer/entities/voice_chat/user_group.dart';

class VoiceChatState {
  final ChannelState channelState;
  final bool isConnected;
  final String? serverUrl;
  final String? error;

  VoiceChatState({
    required this.channelState,
    this.isConnected = false,
    this.serverUrl,
    this.error,
  });

  VoiceChatState copyWith({
    ChannelState? channelState,
    bool? isConnected,
    String? serverUrl,
    String? error,
  }) {
    return VoiceChatState(
      channelState: channelState ?? this.channelState,
      isConnected: isConnected ?? this.isConnected,
      serverUrl: serverUrl ?? this.serverUrl,
      error: error,
    );
  }
}

class VoiceChatNotifier extends StateNotifier<VoiceChatState> {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;

  VoiceChatNotifier()
      : super(VoiceChatState(channelState: ChannelState()));

  Future<void> connect(String serverUrl, String? npub) async {
    try {
      // Disconnect if already connected
      await disconnect();

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
            isConnected: false,
          );
        },
        onDone: () {
          state = state.copyWith(isConnected: false);
        },
      );

      state = state.copyWith(
        isConnected: true,
        serverUrl: serverUrl,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to connect: $e',
        isConnected: false,
      );
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;

    state = state.copyWith(
      isConnected: false,
      serverUrl: null,
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
        case 'error':
          state = state.copyWith(error: data['message'] as String?);
          break;
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to parse message: $e');
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

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

final voiceChatProvider =
    StateNotifierProvider<VoiceChatNotifier, VoiceChatState>((ref) {
  return VoiceChatNotifier();
});
