/// Represents a user in a voice channel
class VoiceUser {
  final String pubkey;
  final String username;
  final String channelId;
  final bool isMuted;
  final bool isDeafened;
  final bool isSpeaking;
  final DateTime joinedAt;

  const VoiceUser({
    required this.pubkey,
    required this.username,
    required this.channelId,
    this.isMuted = false,
    this.isDeafened = false,
    this.isSpeaking = false,
    required this.joinedAt,
  });

  VoiceUser copyWith({
    String? pubkey,
    String? username,
    String? channelId,
    bool? isMuted,
    bool? isDeafened,
    bool? isSpeaking,
    DateTime? joinedAt,
  }) {
    return VoiceUser(
      pubkey: pubkey ?? this.pubkey,
      username: username ?? this.username,
      channelId: channelId ?? this.channelId,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  String toString() => 'VoiceUser($username, muted: $isMuted, deafened: $isDeafened)';
}
