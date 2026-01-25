import 'direct_message.dart';

/// Domain entity representing a 1:1 DM conversation.
///
/// Each conversation is uniquely identified by the peer's pubkey since
/// we only support direct 1:1 messaging (no group chats per NIP-17).
class DmConversation {
  /// Pubkey of the other participant in the conversation
  final String peerPubkey;

  /// Timestamp of the last message (for sorting conversations)
  final int lastMessageAt;

  /// Number of unread messages
  final int unreadCount;

  /// Preview of the last message (truncated if needed)
  final String lastMessagePreview;

  /// Whether the last message was sent by us
  final bool lastMessageIsOutgoing;

  /// The last message in the conversation (optional, for display)
  final DirectMessage? lastMessage;

  DmConversation({
    required this.peerPubkey,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
    this.lastMessageIsOutgoing = false,
    this.lastMessage,
  });

  /// Create an updated conversation with new unread count
  DmConversation copyWith({
    String? peerPubkey,
    int? lastMessageAt,
    int? unreadCount,
    String? lastMessagePreview,
    bool? lastMessageIsOutgoing,
    DirectMessage? lastMessage,
  }) {
    return DmConversation(
      peerPubkey: peerPubkey ?? this.peerPubkey,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageIsOutgoing:
          lastMessageIsOutgoing ?? this.lastMessageIsOutgoing,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DmConversation) return false;
    return peerPubkey == other.peerPubkey;
  }

  @override
  int get hashCode => peerPubkey.hashCode;

  @override
  String toString() {
    return 'DmConversation{peerPubkey: $peerPubkey, lastMessageAt: $lastMessageAt, unreadCount: $unreadCount}';
  }
}
