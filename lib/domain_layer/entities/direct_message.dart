import 'nostr_tag.dart';

/// Status of message sending
enum MessageSendStatus {
  /// Message is being sent
  pending,

  /// Message was sent successfully
  sent,

  /// Message failed to send
  failed,
}

/// Domain entity representing a NIP-17 direct message.
///
/// This represents the decrypted content of a gift-wrapped message (kind 1059).
/// The actual storage on relays uses the gift wrap envelope, but we work with
/// this entity after unwrapping.
class DirectMessage {
  /// Event ID of the gift wrap (kind 1059) - serves as unique identifier
  final String id;

  /// Pubkey of the message sender
  final String senderPubkey;

  /// Pubkey of the peer in this 1:1 conversation
  final String peerPubkey;

  /// Decrypted message content
  final String content;

  /// Timestamp when the message was created (from the rumor)
  final int createdAt;

  /// Whether this message was sent by the current user
  final bool isOutgoing;

  /// Tags from the rumor (for reply references, etc.)
  final List<NostrTag> tags;

  /// Status of message sending (for optimistic UI updates)
  final MessageSendStatus sendStatus;

  /// Event ID of the recipient's gift wrap (for resending failed messages)
  /// Only stored for outgoing messages to non-self recipients.
  /// The self gift wrap ID is the same as [id].
  /// Gift wrap events are stored in NDK cache.
  final String? recipientGiftWrapId;

  /// Human-readable reason why the message failed to send.
  /// Only set when [sendStatus] is [MessageSendStatus.failed].
  final String? failureReason;

  /// Number of relays that have confirmed receipt (transient, not persisted).
  /// Only meaningful while [sendStatus] is [MessageSendStatus.pending].
  final int relaysSent;

  /// Total number of relays being broadcast to (transient, not persisted).
  /// 0 means unknown (NDK is using default relays).
  final int relaysTotal;

  DirectMessage({
    required this.id,
    required this.senderPubkey,
    required this.peerPubkey,
    required this.content,
    required this.createdAt,
    required this.isOutgoing,
    this.tags = const [],
    this.sendStatus = MessageSendStatus.sent,
    this.recipientGiftWrapId,
    this.failureReason,
    this.relaysSent = 0,
    this.relaysTotal = 0,
  });

  /// Create a copy of this message with updated fields
  DirectMessage copyWith({
    String? id,
    String? senderPubkey,
    String? peerPubkey,
    String? content,
    int? createdAt,
    bool? isOutgoing,
    List<NostrTag>? tags,
    MessageSendStatus? sendStatus,
    String? recipientGiftWrapId,
    // Use [clearFailureReason]=true to explicitly set failureReason to null
    bool clearFailureReason = false,
    String? failureReason,
    int? relaysSent,
    int? relaysTotal,
  }) {
    return DirectMessage(
      id: id ?? this.id,
      senderPubkey: senderPubkey ?? this.senderPubkey,
      peerPubkey: peerPubkey ?? this.peerPubkey,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      tags: tags ?? this.tags,
      sendStatus: sendStatus ?? this.sendStatus,
      recipientGiftWrapId: recipientGiftWrapId ?? this.recipientGiftWrapId,
      failureReason: clearFailureReason
          ? null
          : (failureReason ?? this.failureReason),
      relaysSent: relaysSent ?? this.relaysSent,
      relaysTotal: relaysTotal ?? this.relaysTotal,
    );
  }

  /// Get the event ID this message is replying to, if any
  String? get replyToEventId {
    for (final tag in tags) {
      if (tag.type == 'e') {
        return tag.value;
      }
    }
    return null;
  }

  /// Get the quoted event ID, if any (q tag)
  String? get quotedEventId {
    for (final tag in tags) {
      if (tag.type == 'q') {
        return tag.value;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DirectMessage) return false;
    return id == other.id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'DirectMessage{id: $id, senderPubkey: $senderPubkey, peerPubkey: $peerPubkey, createdAt: $createdAt, isOutgoing: $isOutgoing}';
  }
}
