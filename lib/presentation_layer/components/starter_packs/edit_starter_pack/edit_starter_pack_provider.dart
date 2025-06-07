import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/user_metadata.dart';

class StarterPackData {
  final String name; // name as nostr identifier
  final String title;
  final String? description;
  final String? imageUrl;
  final List<UserMetadata>
      selectedUsers; // list over set so odering is possible
  final bool broadcasting;
  final bool broadcasted;

  const StarterPackData({
    required this.name,
    required this.title,
    this.description,
    required this.selectedUsers,
    this.imageUrl,
    required this.broadcasted,
    required this.broadcasting,
    req,
  });

  StarterPackData copyWith({
    String? name,
    String? title,
    String? description,
    List<UserMetadata>? selectedUsers,
    bool? broadcasted,
    bool? broadcasting,
  }) {
    return StarterPackData(
      name: name ?? this.name,
      title: title ?? this.title,
      description: description ?? this.description,
      selectedUsers: selectedUsers ?? this.selectedUsers,
      broadcasted: broadcasted ?? this.broadcasted,
      broadcasting: broadcasting ?? this.broadcasting,
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
  EditStarterPackNotifier(String starterPackId)
      : super(
          StarterPackData(
            name: starterPackId,
            title: '',
            description: '',
            selectedUsers: [],
            broadcasted: false,
            broadcasting: false,
          ),
        ) {
    // Load initial data based on starterPackId
    _loadStarterPack(starterPackId);
  }

  void _loadStarterPack(String id) {
    // todo
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

  void addUser(UserMetadata user) {
    if (state.selectedUsers.contains(user)) {
      return;
    }
    state = state.copyWith(selectedUsers: [user, ...state.selectedUsers]);
  }

  void removeUser(UserMetadata user) {
    state.selectedUsers.remove(user);
    state = state.copyWith(selectedUsers: state.selectedUsers);
  }

  void reorderUser(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final users = List<UserMetadata>.from(state.selectedUsers);
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
  Future<bool> broadcast() async {
    if (!isValid) return false;

    state = state.copyWith(broadcasting: true);

    //todo: real broadcast
    await Future.delayed(Duration(seconds: 5));
    state = state.copyWith(broadcasting: false, broadcasted: true);
    try {
      return true;
    } catch (e) {
      // Handle error
      return false;
    }
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
    EditStarterPackNotifier, StarterPackData, String>(
  (ref, starterPackId) => EditStarterPackNotifier(starterPackId),
);
