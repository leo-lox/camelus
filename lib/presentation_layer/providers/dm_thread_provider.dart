import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain_layer/entities/direct_message.dart';
import 'dm_repository_provider.dart';

/// State for a DM thread (conversation with one peer)
class DmThreadState {
  final String peerPubkey;

  /// Messages from the cache (includes pending, sent, and failed)
  final List<DirectMessage> _cachedMessages;

  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasReachedBeginning;
  final bool isSending;
  final bool hasError;
  final String? errorMessage;

  const DmThreadState({
    required this.peerPubkey,
    List<DirectMessage> cachedMessages = const [],
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.hasReachedBeginning = false,
    this.isSending = false,
    this.hasError = false,
    this.errorMessage,
  }) : _cachedMessages = cachedMessages;

  /// All messages sorted by createdAt
  List<DirectMessage> get messages {
    final sorted = [..._cachedMessages];
    sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return sorted;
  }

  /// Failed messages for retry functionality
  List<DirectMessage> get failedMessages => _cachedMessages
      .where((m) => m.sendStatus == MessageSendStatus.failed)
      .toList();

  DmThreadState copyWith({
    String? peerPubkey,
    List<DirectMessage>? cachedMessages,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? hasReachedBeginning,
    bool? isSending,
    bool? hasError,
    String? errorMessage,
  }) {
    return DmThreadState(
      peerPubkey: peerPubkey ?? this.peerPubkey,
      cachedMessages: cachedMessages ?? _cachedMessages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasReachedBeginning: hasReachedBeginning ?? this.hasReachedBeginning,
      isSending: isSending ?? this.isSending,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for managing a single DM thread (conversation)
///
/// Use with the family modifier to get a thread for a specific peer:
/// ```dart
/// ref.watch(dmThreadProvider('peer-pubkey'))
/// ```
final dmThreadProvider =
    StateNotifierProvider.family<DmThreadNotifier, DmThreadState, String>((
      ref,
      peerPubkey,
    ) {
      return DmThreadNotifier(ref, peerPubkey);
    });

class DmThreadNotifier extends StateNotifier<DmThreadState> {
  final Ref ref;
  final String peerPubkey;

  StreamSubscription? _messagesSubscription;
  StreamSubscription? _newMessageSubscription;

  DmThreadNotifier(this.ref, this.peerPubkey)
    : super(DmThreadState(peerPubkey: peerPubkey, isLoading: true)) {
    _setupMessagesWatch();
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _newMessageSubscription?.cancel();
    super.dispose();
  }

  void _setupMessagesWatch() async {
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Not logged in',
      );
      return;
    }

    // Watch messages from local cache
    _messagesSubscription = repository
        .watchMessages(peerPubkey)
        .listen(
          (messages) {
            // Update messages from cache
            state = state.copyWith(
              cachedMessages: messages,
              isLoading: false,
              hasError: false,
            );

            // Check hasReachedBeginning async (non-blocking)
            repository.hasReachedBeginning(peerPubkey).then((reachedBeginning) {
              state = state.copyWith(hasReachedBeginning: reachedBeginning);
            });
          },
          onError: (error) {
            log('DM Thread: Error watching messages: $error');
            state = state.copyWith(
              isLoading: false,
              hasError: true,
              errorMessage: error.toString(),
            );
          },
        );

    // Subscribe to new messages and filter for this conversation
    _newMessageSubscription = repository.subscribeToNewMessages().listen((
      message,
    ) {
      if (message.peerPubkey == peerPubkey) {
        log('DM Thread: New message in conversation');
        // Messages will auto-update via watchMessages
      }
    });

    // Mark as read when viewing
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return;

    await repository.markConversationAsRead(peerPubkey);
  }

  /// Send a message in this conversation
  /// The message appears instantly via watchMessages (cached before broadcast)
  Future<bool> sendMessage(String content, {String? replyToEventId}) async {
    if (content.trim().isEmpty) return false;

    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return false;

    state = state.copyWith(isSending: true);

    try {
      // Send message - it's cached locally before broadcast,
      // so it appears instantly via watchMessages
      await repository.sendMessage(
        recipientPubkey: peerPubkey,
        content: content.trim(),
        replyToEventId: replyToEventId,
      );

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      log('DM Thread: Error sending message: $e');
      // Failed messages are saved to DB by repository with sendStatus: failed
      // They will appear via watchMessages
      state = state.copyWith(
        isSending: false,
        hasError: true,
        errorMessage: 'Failed to send message',
      );
      return false;
    }
  }

  /// Retry sending a failed message by resending the cached gift wrap
  Future<bool> retrySendMessage(String messageId) async {
    final message = state.failedMessages
        .where((m) => m.id == messageId)
        .firstOrNull;

    if (message == null) {
      log('DM Thread: Cannot retry - message not found');
      return false;
    }

    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return false;

    // Resend the existing cached gift wrap event
    final success = await repository.resendMessage(messageId);

    log('DM Thread: Retry ${success ? 'successful' : 'failed'} for $messageId');

    return success;
  }

  /// Remove a failed message
  Future<void> removeFailedMessage(String messageId) async {
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return;

    await repository.deleteMessage(messageId);
  }

  /// Mark conversation as read (call when entering the thread)
  Future<void> markAsRead() async {
    await _markAsRead();
  }

  /// Load older messages (pagination)
  Future<void> loadOlderMessages() async {
    if (state.isLoadingOlder || state.hasReachedBeginning) return;

    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return;

    state = state.copyWith(isLoadingOlder: true);

    try {
      // loadOlderMessages returns true if new messages were found
      final foundMore = await repository.loadOlderMessages();

      state = state.copyWith(
        isLoadingOlder: false,
        // If no more messages found, we've reached the beginning
        hasReachedBeginning: !foundMore,
      );
    } catch (e) {
      log('DM Thread: Error loading older messages: $e');
      state = state.copyWith(isLoadingOlder: false);
    }
  }

  /// Delete a message
  /// Returns true if deleted from relays, false if only deleted locally
  Future<bool> deleteMessage(String messageId) async {
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return false;

    // Check if it's a failed message (not on relays yet)
    final isFailedMessage = state.failedMessages.any((m) => m.id == messageId);

    // Optimistic update: remove message from UI immediately
    final originalMessages = state._cachedMessages;
    final messageToDelete = originalMessages
        .where((m) => m.id == messageId)
        .firstOrNull;

    if (messageToDelete != null) {
      state = state.copyWith(
        cachedMessages: originalMessages
            .where((m) => m.id != messageId)
            .toList(),
      );
    }

    try {
      final deletedFromRelays = await repository.deleteMessage(messageId);
      if (isFailedMessage) {
        return true; // Failed messages weren't on relays
      }
      if (deletedFromRelays) {
        log('DM Thread: Message deleted from relays successfully');
      } else {
        log(
          'DM Thread: Message deleted locally, relays may not support deletion',
        );
      }
      return deletedFromRelays;
    } catch (e) {
      log('DM Thread: Error deleting message: $e');
      // Rollback: restore message on failure
      if (messageToDelete != null) {
        state = state.copyWith(cachedMessages: originalMessages);
      }
      return false;
    }
  }
}

/// Provider to check if we have an existing conversation with a peer
final hasConversationWithProvider = FutureProvider.family<bool, String>((
  ref,
  peerPubkey,
) async {
  final repository = ref.watch(dmRepositoryProvider);
  if (repository == null) return false;

  final conversation = await repository.getConversation(peerPubkey);
  return conversation != null;
});
