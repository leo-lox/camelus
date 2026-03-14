import 'package:camelus/presentation_layer/providers/following_contact_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ndk_provider.dart';

class ModerationState {
  final Set<String> trustedPubkeys;

  ModerationState({required this.trustedPubkeys});

  ModerationState copyWith({Set<String>? trustedPubkeys}) {
    return ModerationState(
      trustedPubkeys: trustedPubkeys ?? this.trustedPubkeys,
    );
  }
}

final moderationStateProvider =
    NotifierProvider<ModerationNotifier, ModerationState>(
      ModerationNotifier.new,
    );

class ModerationNotifier extends Notifier<ModerationState> {
  @override
  ModerationState build() {
    final myUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();

    // Initialize with empty set first
    final initialState = ModerationState(trustedPubkeys: {});

    // Skip setup if no pubkey (read-only mode)
    if (myUserPubkey == null) {
      return initialState;
    }

    // Listen to contact changes
    ref.listen<ContactListState>(contactListStateProvider(myUserPubkey), (
      previous,
      next,
    ) {
      _updateTrustedPubkeys(next);
    });

    // Load initial contacts and return state with them
    final contacts = ref.read(contactListStateProvider(myUserPubkey));
    final myContacts = contacts.contactList.contacts.toSet();

    return ModerationState(trustedPubkeys: myContacts);
  }

  void _updateTrustedPubkeys(ContactListState contactsState) {
    final myContacts = contactsState.contactList.contacts.toSet();
    state = state.copyWith(trustedPubkeys: myContacts);
  }

  /// tests a pubkey against the trusted pubkeys
  bool isPubkeyTrusted(String pubkey) {
    return state.trustedPubkeys.contains(pubkey);
  }
}
