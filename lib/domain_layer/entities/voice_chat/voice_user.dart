import 'user_group.dart';

class VoiceUser {
  final String id;
  final String? npub;
  final String? displayName;
  final UserGroup group;
  final String? channelId;
  final bool isSpeaking;
  final bool isMuted;

  VoiceUser({
    required this.id,
    this.npub,
    this.displayName,
    required this.group,
    this.channelId,
    this.isSpeaking = false,
    this.isMuted = false,
  });

  VoiceUser copyWith({
    String? id,
    String? npub,
    String? displayName,
    UserGroup? group,
    String? channelId,
    bool? isSpeaking,
    bool? isMuted,
  }) {
    return VoiceUser(
      id: id ?? this.id,
      npub: npub ?? this.npub,
      displayName: displayName ?? this.displayName,
      group: group ?? this.group,
      channelId: channelId ?? this.channelId,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}
