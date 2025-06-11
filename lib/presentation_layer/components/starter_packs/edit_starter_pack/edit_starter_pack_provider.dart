import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data_layer/data_sources/serverpod_data_source.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../../domain_layer/usecases/get_nostr_lists.dart';
import '../../../providers/nostr_list_provider.dart';
import '../../../providers/nostr_lists_follow_state_provider.dart';
import '../../../providers/serverpod_provider.dart';

class StarterPackData {
  final String name; // name as nostr identifier
  final String title;
  final String? description;
  final String? imageUrl;
  final List<String> selectedUsers; // list over set so odering is possible
  final bool broadcasting;
  final bool broadcasted;
  final String? shortLinkPart;

  const StarterPackData({
    required this.name,
    required this.title,
    this.description,
    required this.selectedUsers,
    this.imageUrl,
    required this.broadcasted,
    required this.broadcasting,
    this.shortLinkPart,
  });

  StarterPackData copyWith({
    String? name,
    String? title,
    String? description,
    List<String>? selectedUsers,
    bool? broadcasted,
    bool? broadcasting,
    String? shortLinkPart,
  }) {
    return StarterPackData(
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      selectedUsers: selectedUsers ?? this.selectedUsers,
      broadcasted: broadcasted ?? this.broadcasted,
      broadcasting: broadcasting ?? this.broadcasting,
      shortLinkPart: shortLinkPart ?? this.shortLinkPart,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StarterPackData &&
        other.title == title &&
        other.description == description;
  }

  @override
  int get hashCode => title.hashCode ^ description.hashCode;
}

// State notifier for managing starter pack data
class EditStarterPackNotifier extends StateNotifier<StarterPackData> {
  final GetNostrLists _listsProvider;
  final NostrListsFollowState _listsState;
  final ServerpodDataSource _serverpodProvider;

  EditStarterPackNotifier(
    this._listsProvider,
    this._listsState,
    this._serverpodProvider,
    StarterPackIdentifier identifier,
  ) : super(
          StarterPackData(
            name: identifier.name,
            title: '',
            description: '',
            selectedUsers: [],
            broadcasted: false,
            broadcasting: false,
          ),
        ) {
    // Load initial data based on starterPackId
    _loadStarterPack(identifier);
  }

  void _loadStarterPack(StarterPackIdentifier identifier) {
    try {
      final myList = _listsState.publicNostrFollowSets
          .where((l) => l.name == identifier.name)
          .first;
      state = state.copyWith(
          name: myList.name,
          title: myList.title,
          description: myList.description,
          selectedUsers: myList.pubKeys.map((e) => e.value).toList());
    } catch (_) {
      // new set, do nothing
    }
  }

  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
  }

  void updateData({String? title, String? description}) {
    state = state.copyWith(
      title: title,
      description: description,
    );
  }

  void addUser(String pubkeyey) {
    if (state.selectedUsers.contains(pubkeyey)) {
      return;
    }
    state = state.copyWith(selectedUsers: [pubkeyey, ...state.selectedUsers]);
  }

  void removeUser(String pubkey) {
    state.selectedUsers.remove(pubkey);
    state = state.copyWith(selectedUsers: state.selectedUsers);
  }

  void reorderUser(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final users = List<String>.from(state.selectedUsers);
    final user = users.removeAt(oldIndex);
    users.insert(newIndex, user);

    state = state.copyWith(selectedUsers: users);
  }

  // Validation methods
  bool get isTitleValid =>
      state.title.trim().isNotEmpty && state.title.length <= 40;
  bool get isValid => isTitleValid;

  int get titleCharacterCount => state.title.length;

  // Save method
  Future<bool> broadcast(NostrStarterPack pack) async {
    if (!isValid) return false;

    state = state.copyWith(broadcasting: true);

    final result = await _listsProvider.broadcastStarterPack(starterPack: pack);

    String? shortLinkPart;
    try {
      shortLinkPart = await _serverpodProvider.client.linkShorter.shortInvite(
        invitedByNpub: pack.pubKey,
        listName: pack.name,
        listNpub: pack.pubKey,
      );
    } catch (_) {
      //server down
    }

    print(result);

    state = state.copyWith(
      broadcasting: false,
      broadcasted: true,
      shortLinkPart: shortLinkPart,
    );

    return true;
  }

  // resets the state
  void reset() {
    state = state.copyWith(
      broadcasted: false,
      broadcasting: false,
    );
  }
}

final editStarterPackProvider = StateNotifierProvider.family<
    EditStarterPackNotifier, StarterPackData, StarterPackIdentifier>(
  (ref, identifier) {
    final listStateProvider =
        ref.watch(nostrListsFollowStateProvider(identifier.pubkey));
    final listProvider = ref.watch(nostrListProvider);
    final serverpodProv = ref.watch(serverpodProvider);
    return EditStarterPackNotifier(
      listProvider,
      listStateProvider,
      serverpodProv,
      identifier,
    );
  },
);
