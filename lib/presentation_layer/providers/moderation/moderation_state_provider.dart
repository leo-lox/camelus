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

    // Skip setup if no pubkey (read-only mode)
    if (myUserPubkey != null) {
      // Listen to contact changes
      ref.listen<ContactListState>(contactListStateProvider(myUserPubkey), (
        previous,
        next,
      ) {
        _updateTrustedPubkeys(next);
      });

      // Load initial state
      final contacts = ref.read(contactListStateProvider(myUserPubkey));
      _updateTrustedPubkeys(contacts);
    }

    return ModerationState(trustedPubkeys: {});
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
