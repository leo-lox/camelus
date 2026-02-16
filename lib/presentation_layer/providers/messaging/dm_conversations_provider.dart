import 'dart:async';
import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/dm_conversation.dart';
import '../../../domain_layer/repositories/direct_message_repository.dart';
import 'dm_repository_provider.dart';

/// State for the DM conversations list
class DmConversationsState {
  final List<DmConversation> conversations;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;
  final bool initialFetchDone;

  const DmConversationsState({
    this.conversations = const [],
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.initialFetchDone = false,
  });

  DmConversationsState copyWith({
    List<DmConversation>? conversations,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    bool? initialFetchDone,
  }) {
    return DmConversationsState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      initialFetchDone: initialFetchDone ?? this.initialFetchDone,
    );
  }
}

/// Provider for managing DM conversations list
final dmConversationsProvider =
    NotifierProvider<DmConversationsNotifier, DmConversationsState>(
      DmConversationsNotifier.new,
    );

class DmConversationsNotifier extends Notifier<DmConversationsState> {
  StreamSubscription? _conversationsSubscription;
  StreamSubscription? _newMessageSubscription;

  @override
  DmConversationsState build() {
    // Clean up on dispose
    ref.onDispose(() {
      _conversationsSubscription?.cancel();
      _newMessageSubscription?.cancel();
    });

    // Check if user is logged in before starting
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) {
      return const DmConversationsState(
        isLoading: false,
        hasError: true,
        errorMessage: 'Not logged in',
      );
    }

    // Start watching conversations
    _setupConversationsWatch(repository);

    return const DmConversationsState(isLoading: true);
  }

  void _setupConversationsWatch(DirectMessageRepository repository) {
    // Watch conversations from local cache
    _conversationsSubscription = repository.watchConversations().listen(
      (conversations) {
        state = state.copyWith(
          conversations: conversations,
          isLoading: false,
          hasError: false,
        );
      },
      onError: (error) {
        log('DM Conversations: Error watching conversations: $error');
        state = state.copyWith(
          isLoading: false,
          hasError: true,
          errorMessage: error.toString(),
        );
      },
    );

    // Subscribe to new messages for real-time updates
    _newMessageSubscription = repository.subscribeToNewMessages().listen(
      (message) {
        log('DM: New message received from ${message.senderPubkey}');
        // The conversation list will auto-update via watchConversations
      },
      onError: (error) {
        log('DM: Error in new message subscription: $error');
      },
    );
  }

  /// Fetch messages from relays (for initial load or refresh)
  Future<void> fetchMessages({int? since}) async {
    final repository = ref.read(dmRepositoryProvider);
    if (repository == null) return;

    state = state.copyWith(isLoading: true);

    try {
      await repository.fetchMessages(since: since);
      state = state.copyWith(isLoading: false, initialFetchDone: true);
    } catch (e) {
      log('DM: Error fetching messages: $e');
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Refresh conversations (fetch new messages)
  Future<void> refresh() async {
    // Get the most recent message timestamp to fetch from
    int? since;
    if (state.conversations.isNotEmpty) {
      since = state.conversations
          .map((c) => c.lastMessageAt)
          .reduce((a, b) => a > b ? a : b);
    }

    await fetchMessages(since: since);
  }
}

/// Provider for watching total unread count
final dmUnreadCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(dmRepositoryProvider);
  if (repository == null) {
    return Stream.value(0);
  }
  return repository.watchTotalUnreadCount();
});
