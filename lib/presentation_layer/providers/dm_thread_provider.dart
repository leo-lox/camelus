import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain_layer/entities/direct_message.dart';
import 'dm_repository_provider.dart';

/// State for a DM thread (conversation with one peer)
class DmThreadState {
  final String peerPubkey;
  final List<DirectMessage> messages;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool hasReachedBeginning;
  final bool isSending;
  final bool hasError;
  final String? errorMessage;

  const DmThreadState({
    required this.peerPubkey,
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.hasReachedBeginning = false,
    this.isSending = false,
    this.hasError = false,
    this.errorMessage,
  });

  DmThreadState copyWith({
    String? peerPubkey,
    List<DirectMessage>? messages,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? hasReachedBeginning,
    bool? isSending,
    bool? hasError,
    String? errorMessage,
  }) {
    return DmThreadState(
      peerPubkey: peerPubkey ?? this.peerPubkey,
      messages: messages ?? this.messages,
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
            // Update messages immediately (no loading delay)
            state = state.copyWith(
              messages: messages,
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
  Future<bool> sendMessage(String content, {String? replyToEventId}) async {
    if (content.trim().isEmpty) return false;

    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return false;

    state = state.copyWith(isSending: true);

    try {
      await repository.sendMessage(
        recipientPubkey: peerPubkey,
        content: content.trim(),
        replyToEventId: replyToEventId,
      );

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      log('DM Thread: Error sending message: $e');
      state = state.copyWith(
        isSending: false,
        hasError: true,
        errorMessage: 'Failed to send message',
      );
      return false;
    }
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

  /// Delete a message (optimistic UI)
  Future<bool> deleteMessage(String messageId) async {
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return false;

    // Optimistic update: remove from UI immediately
    final originalMessages = state.messages;
    state = state.copyWith(
      messages: originalMessages.where((m) => m.id != messageId).toList(),
    );

    try {
      final success = await repository.deleteMessage(messageId);
      if (success) {
        log('DM Thread: Message deleted successfully');
      } else {
        // Restore on failure
        state = state.copyWith(messages: originalMessages);
      }
      return success;
    } catch (e) {
      log('DM Thread: Error deleting message: $e');
      // Restore on error
      state = state.copyWith(messages: originalMessages);
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
