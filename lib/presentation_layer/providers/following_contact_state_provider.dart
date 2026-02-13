import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../../domain_layer/entities/contact_list.dart';
import '../../domain_layer/usecases/follow.dart';
import 'following_provider.dart';
import 'ndk_provider.dart'; // Import your following provider

class ContactListState {
  final bool isLoading;
  final ContactList contactList;

  ContactListState({required this.isLoading, required this.contactList});

  ContactListState copyWith({bool? isLoading, ContactList? contactList}) {
    return ContactListState(
      isLoading: isLoading ?? this.isLoading,
      contactList: contactList ?? this.contactList,
    );
  }
}

final contactListStateProvider =
    NotifierProvider.family<ContactListNotifier, ContactListState, String>(
      ContactListNotifier.new,
    );

/// convenience provider
final contactListSelfStateProvider = Provider<ContactListState>((ref) {
  final selfPubkey = ref.watch(ndkProvider).accounts.getPublicKey();

  // If no pubkey (read-only mode), return empty contact list
  if (selfPubkey == null) {
    return ContactListState(
      isLoading: false,
      contactList: ContactList(
        pubKey: '',
        contacts: [],
        contactRelays: [],
        petnames: [],
        followedTags: [],
        followedCommunities: [],
        followedEvents: [],
        sources: [],
        createdAt: 0,
        loadedTimestamp: null,
      ),
    );
  }

  return ref.watch(contactListStateProvider(selfPubkey));
});

class ContactListNotifier extends Notifier<ContactListState> {
  late final Follow _followUseCase;
  late final String _pubkey;

  StreamSubscription<ContactList?>? _subscription;

  ContactListNotifier(String pubkey) : _pubkey = pubkey;

  @override
  ContactListState build() {
    final follow = ref.watch(followingProvider);
    _followUseCase = follow;

    ref.onDispose(() {
      _subscription?.cancel();
    });

    _initializeState();

    return ContactListState(
      isLoading: true,
      contactList: ContactList(
        pubKey: _pubkey,
        contacts: [],
        contactRelays: [],
        petnames: [],
        followedTags: [],
        followedCommunities: [],
        followedEvents: [],
        sources: [],
        createdAt: 0,
        loadedTimestamp: null,
      ),
    );
  }

  void _initializeState() {
    _subscription = _followUseCase
        .getContactsStream(_pubkey)
        .listen(
          (contactList) {
            state = state.copyWith(isLoading: false, contactList: contactList);
          },
          onError: (error) {
            state = state.copyWith(
              isLoading: false,
              contactList: null, // Set to null on error
            );
            // Handle the error appropriately, e.g., log it
            if (kDebugMode) {
              print('Error fetching contact list: $error');
            }
          },
        );
  }

  Future followUser(String pubkey) async {
    final result = await _followUseCase.followUser(pubkey);
    if (result != null) {
      state = state.copyWith(contactList: result);
    }
  }

  Future unfollowUser(String pubkey) async {
    final result = await _followUseCase.unfollowUser(pubkey);
    if (result != null) {
      state = state.copyWith(contactList: result);
    }
  }

  bool isFollowing(String pubkey) {
    return state.contactList.contacts.contains(pubkey);
  }

  Future<void> setContacts(List<String> pubkeys) async {
    return _followUseCase.setContacts(pubkeys);
  }
}
