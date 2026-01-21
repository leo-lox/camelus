import 'package:objectbox/objectbox.dart';

/// ObjectBox entity for caching decrypted NIP-17 direct messages.
///
/// This stores the result of unwrapping gift wraps (kind 1059) so we don't
/// need to decrypt them again on subsequent loads.
@Entity()
class DbNip17Message {
  @Id()
  int dbId = 0;

  /// Event ID of the gift wrap (kind 1059) - unique identifier
  @Unique()
  String eventId = '';

  /// Pubkey of the message sender (from the unwrapped rumor)
  @Index()
  String senderPubkey = '';

  /// Pubkey of the peer in this 1:1 conversation
  @Index()
  String peerPubkey = '';

  /// Decrypted message content
  String content = '';

  /// Timestamp from the rumor (not the gift wrap)
  @Index()
  int createdAt = 0;

  /// JSON-encoded tags from the rumor (for replies, etc.)
  String tags = '';

  /// Event ID of the message being replied to (if any)
  String? replyToEventId;

  /// Whether this message was sent by the current user
  bool isOutgoing = false;

  DbNip17Message({
    this.eventId = '',
    this.senderPubkey = '',
    this.peerPubkey = '',
    this.content = '',
    this.createdAt = 0,
    this.tags = '',
    this.replyToEventId,
    this.isOutgoing = false,
  });
}
