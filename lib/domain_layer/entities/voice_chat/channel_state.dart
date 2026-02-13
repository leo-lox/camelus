import 'voice_channel.dart';
import 'voice_user.dart';

class ChannelState {
  final List<VoiceChannel> channels;
  final List<VoiceUser> users;
  final String? currentUserId;
  final String? currentChannelId;

  ChannelState({
    this.channels = const [],
    this.users = const [],
    this.currentUserId,
    this.currentChannelId,
  });

  ChannelState copyWith({
    List<VoiceChannel>? channels,
    List<VoiceUser>? users,
    String? currentUserId,
    String? currentChannelId,
  }) {
    return ChannelState(
      channels: channels ?? this.channels,
      users: users ?? this.users,
      currentUserId: currentUserId ?? this.currentUserId,
      currentChannelId: currentChannelId ?? this.currentChannelId,
    );
  }

  List<VoiceChannel> getChildChannels(String? parentId) {
    return channels
        .where((channel) => channel.parentId == parentId)
        .toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  List<VoiceUser> getUsersInChannel(String channelId) {
    return users.where((user) => user.channelId == channelId).toList();
  }
}
