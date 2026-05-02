import '../entities/direct_message.dart';
import '../entities/dm_conversation.dart';

abstract class AppDb {
  // ============ Key-Value ============

  Future<void> save({required String key, required String value});
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> clear();

  // ============ DM Messages ============

  /// Upsert a message. Preserves any persisted gift-wrap JSON already stored.
  Future<void> dmPutMessage({
    required String ownerPubkey,
    required DirectMessage message,
  });

  /// Retrieve a single message by gift-wrap event ID.
  Future<DirectMessage?> dmGetMessage({
    required String ownerPubkey,
    required String giftWrapId,
  });

  /// All messages for a peer, ordered ascending by [createdAt].
  Future<List<DirectMessage>> dmGetMessagesByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  });

  /// Oldest message across *all* peers for this owner.
  Future<DirectMessage?> dmGetOldestMessage({required String ownerPubkey});

  /// Oldest message with a specific peer.
  Future<DirectMessage?> dmGetOldestMessageByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  });

  /// Most-recent message with a specific peer.
  Future<DirectMessage?> dmGetLatestMessageByPeer({
    required String ownerPubkey,
    required String peerPubkey,
  });

  /// Delete a message by gift-wrap event ID.
  Future<void> dmDeleteMessage({
    required String ownerPubkey,
    required String giftWrapId,
  });

  /// From [peerPubkeys], return those that have at least one outgoing message.
  Future<Set<String>> dmGetPeersWithOutgoingMessages({
    required String ownerPubkey,
    required List<String> peerPubkeys,
  });

  /// Total number of messages stored for this owner.
  Future<int> dmCountMessages({required String ownerPubkey});

  /// Persist serialised gift-wrap JSON alongside the message record so that
  /// resend works after an app restart (NDK in-memory cache is cleared).
  Future<void> dmPersistGiftWraps({
    required String ownerPubkey,
    required String messageId,
    required String selfGiftWrapJson,
    String? recipientGiftWrapJson,
  });

  /// Retrieve one of the stored gift-wrap JSON strings.
  /// [isSelf] selects the self or recipient gift-wrap JSON.
  Future<String?> dmGetGiftWrapJson({
    required String ownerPubkey,
    required String messageId,
    required bool isSelf,
  });

  // ============ DM Conversations ============

  /// All conversations for this owner, ordered descending by [lastMessageAt].
  /// Each returned [DmConversation] has [lastMessage] populated.
  Future<List<DmConversation>> dmGetConversations({
    required String ownerPubkey,
  });

  /// A single conversation. Returns `null` if none exists.
  /// The returned [DmConversation] has [lastMessage] populated.
  Future<DmConversation?> dmGetConversation({
    required String ownerPubkey,
    required String peerPubkey,
  });

  /// Upsert a conversation record.
  Future<void> dmPutConversation({
    required String ownerPubkey,
    required DmConversation conversation,
  });

  /// Set the unread count to zero for a conversation.
  Future<void> dmMarkConversationRead({
    required String ownerPubkey,
    required String peerPubkey,
  });

  /// Sum of unread counts across all conversations for this owner.
  Future<int> dmGetTotalUnreadCount({required String ownerPubkey});

  /// Delete a conversation record (called when the last message is removed).
  Future<void> dmDeleteConversation({
    required String ownerPubkey,
    required String peerPubkey,
  });
}
