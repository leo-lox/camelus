import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/dm_conversation.dart';
import 'dm_conversations_provider.dart';
import 'dm_repository_provider.dart';
import '../following_contact_state_provider.dart';
import '../ndk_provider.dart';

/// Categories for DM conversations
enum DmCategory { follows, known, requests }

/// State containing categorized DM conversations
class CategorizedDmState {
  final List<DmConversation> follows;
  final List<DmConversation> known;
  final List<DmConversation> requests;
  final DmConversation? noteToSelf;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  const CategorizedDmState({
    this.follows = const [],
    this.known = const [],
    this.requests = const [],
    this.noteToSelf,
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  CategorizedDmState copyWith({
    List<DmConversation>? follows,
    List<DmConversation>? known,
    List<DmConversation>? requests,
    DmConversation? noteToSelf,
    bool clearNoteToSelf = false,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return CategorizedDmState(
      follows: follows ?? this.follows,
      known: known ?? this.known,
      requests: requests ?? this.requests,
      noteToSelf: clearNoteToSelf ? null : (noteToSelf ?? this.noteToSelf),
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get unread count for a specific category
  int getUnreadCount(DmCategory category) {
    switch (category) {
      case DmCategory.follows:
        return follows.fold(0, (sum, c) => sum + c.unreadCount);
      case DmCategory.known:
        return known.fold(0, (sum, c) => sum + c.unreadCount);
      case DmCategory.requests:
        return requests.fold(0, (sum, c) => sum + c.unreadCount);
    }
  }
}

/// Provider for categorized DM conversations
final dmCategoriesProvider =
    NotifierProvider<DmCategoriesNotifier, CategorizedDmState>(
      DmCategoriesNotifier.new,
    );

class DmCategoriesNotifier extends Notifier<CategorizedDmState> {
  @override
  CategorizedDmState build() {
    // Listen to conversations provider
    ref.listen(dmConversationsProvider, (previous, next) {
      _categorizeConversations(next);
    });

    // Listen to contact list changes
    ref.listen(contactListSelfStateProvider, (previous, next) {
      // Re-categorize when contacts change
      final conversationsState = ref.read(dmConversationsProvider);
      _categorizeConversations(conversationsState);
    });

    // Initial categorization
    final conversationsState = ref.read(dmConversationsProvider);
    if (conversationsState.conversations.isNotEmpty) {
      _categorizeConversationsSync(conversationsState);
    }

    return CategorizedDmState(isLoading: conversationsState.isLoading);
  }

  void _categorizeConversations(DmConversationsState conversationsState) async {
    if (conversationsState.isLoading && state.follows.isEmpty) {
      state = state.copyWith(isLoading: true);
      return;
    }

    if (conversationsState.hasError) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: conversationsState.errorMessage,
      );
      return;
    }

    final myPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    if (myPubkey == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    final conversations = conversationsState.conversations;
    final contactList = ref.read(contactListSelfStateProvider).contactList;
    final followedPubkeys = contactList.contacts.toSet();

    // Separate "Note to Self"
    DmConversation? noteToSelf;
    final otherConversations = <DmConversation>[];

    for (final conversation in conversations) {
      if (conversation.peerPubkey == myPubkey) {
        noteToSelf = conversation;
      } else {
        otherConversations.add(conversation);
      }
    }

    // Categorize: follows vs (known/requests)
    final followsList = <DmConversation>[];
    final needsOutgoingCheck = <DmConversation>[];

    for (final conversation in otherConversations) {
      if (followedPubkeys.contains(conversation.peerPubkey)) {
        followsList.add(conversation);
      } else {
        needsOutgoingCheck.add(conversation);
      }
    }

    // Check outgoing messages for non-follows
    final knownList = <DmConversation>[];
    final requestsList = <DmConversation>[];

    if (needsOutgoingCheck.isNotEmpty) {
      final repository = ref.read(dmRepositoryProvider);
      if (repository != null) {
        final peerPubkeys = needsOutgoingCheck
            .map((c) => c.peerPubkey)
            .toList();
        final peersWithOutgoing = await repository.getPeersWithOutgoingMessages(
          peerPubkeys,
        );

        for (final conversation in needsOutgoingCheck) {
          if (peersWithOutgoing.contains(conversation.peerPubkey)) {
            knownList.add(conversation);
          } else {
            requestsList.add(conversation);
          }
        }
      } else {
        // No repository, put all in requests
        requestsList.addAll(needsOutgoingCheck);
      }
    }

    state = CategorizedDmState(
      follows: followsList,
      known: knownList,
      requests: requestsList,
      noteToSelf: noteToSelf,
      isLoading: false,
      hasError: false,
    );
  }

  /// Synchronous initial categorization (without outgoing check)
  void _categorizeConversationsSync(DmConversationsState conversationsState) {
    final myPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    if (myPubkey == null) return;

    final conversations = conversationsState.conversations;
    final contactList = ref.read(contactListSelfStateProvider).contactList;
    final followedPubkeys = contactList.contacts.toSet();

    DmConversation? noteToSelf;
    final followsList = <DmConversation>[];
    final otherList = <DmConversation>[];

    for (final conversation in conversations) {
      if (conversation.peerPubkey == myPubkey) {
        noteToSelf = conversation;
      } else if (followedPubkeys.contains(conversation.peerPubkey)) {
        followsList.add(conversation);
      } else {
        otherList.add(conversation);
      }
    }

    // Initially put non-follows in requests, will be re-categorized async
    state = CategorizedDmState(
      follows: followsList,
      known: [],
      requests: otherList,
      noteToSelf: noteToSelf,
      isLoading: true,
    );

    // Trigger async categorization
    _categorizeConversations(conversationsState);
  }
}
