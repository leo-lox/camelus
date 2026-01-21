import '../entities/direct_message.dart';
import '../entities/dm_conversation.dart';

/// Abstract repository for NIP-17 direct message operations.
///
/// This repository handles:
/// - Fetching and caching gift-wrapped messages
/// - Managing conversation state
/// - Sending encrypted DMs
abstract class DirectMessageRepository {
  // ============ Conversations ============

  /// Watch all conversations, sorted by lastMessageAt descending
  Stream<List<DmConversation>> watchConversations();

  /// Get a specific conversation by peer pubkey
  Future<DmConversation?> getConversation(String peerPubkey);

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String peerPubkey);

  /// Watch the total unread count across all conversations
  Stream<int> watchTotalUnreadCount();

  // ============ Messages ============

  /// Watch messages for a specific conversation (1:1 with peer)
  Stream<List<DirectMessage>> watchMessages(String peerPubkey);

  /// Fetch messages from relays.
  /// Uses ndk.fetchedRanges to avoid re-fetching already fetched time ranges.
  Future<void> fetchMessages({int? since, int? until});

  /// Load older messages (before the oldest currently loaded message).
  /// Returns true if any new messages were found, false if we've reached the beginning.
  Future<bool> loadOlderMessages();

  /// Get the oldest message timestamp for a conversation.
  /// Returns null if no messages exist.
  Future<int?> getOldestMessageTimestamp(String peerPubkey);

  /// Check if we've reached the beginning of conversation history.
  /// Uses fetchedRanges to determine if there are gaps before the oldest message.
  Future<bool> hasReachedBeginning(String peerPubkey);

  /// Subscribe to new incoming messages in real-time
  Stream<DirectMessage> subscribeToNewMessages();

  // ============ Sending ============

  /// Send a direct message to a recipient (1:1)
  Future<void> sendMessage({
    required String recipientPubkey,
    required String content,
    String? replyToEventId,
  });

  // ============ Cache ============

  /// Get a cached (already decrypted) message by gift wrap event ID
  Future<DirectMessage?> getCachedMessage(String giftWrapId);

  /// Cache a decrypted message to avoid re-decryption
  Future<void> cacheDecryptedMessage(DirectMessage message);

  // ============ Cleanup ============

  /// Close any active subscriptions
  Future<void> closeSubscriptions();
}
