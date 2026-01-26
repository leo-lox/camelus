import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for tracking NIP-17 DM conversations (1:1 only).
///
/// Each conversation is identified by the peer's pubkey since we only
/// support 1:1 direct messages (no group chats).
@Entity()
class DbNip17Conversation {
  @Id()
  int dbId = 0;

  /// Pubkey of the user who owns this conversation (the logged-in user)
  @Index()
  String ownerPubkey = '';

  /// Pubkey of the other participant in the conversation
  /// Combined with ownerPubkey forms a unique conversation identifier
  @Index()
  String peerPubkey = '';

  /// Timestamp of the last message (for sorting conversations)
  @Index()
  int lastMessageAt = 0;

  /// Number of unread messages in this conversation
  int unreadCount = 0;

  /// Preview of the last message content (truncated)
  String lastMessagePreview = '';

  /// Whether the last message was sent by us
  bool lastMessageIsOutgoing = false;

  DbNip17Conversation({
    this.ownerPubkey = '',
    this.peerPubkey = '',
    this.lastMessageAt = 0,
    this.unreadCount = 0,
    this.lastMessagePreview = '',
    this.lastMessageIsOutgoing = false,
  });
}
