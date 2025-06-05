import 'package:flutter_riverpod/flutter_riverpod.dart';

class StarterPackData {
  final String title;
  final String description;

  const StarterPackData({
    required this.title,
    required this.description,
  });

  StarterPackData copyWith({
    String? title,
    String? description,
  }) {
    return StarterPackData(
      title: title ?? this.title,
      description: description ?? this.description,
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
          const StarterPackData(
            title: '',
            description: '',
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

  // Validation methods
  bool get isTitleValid =>
      state.title.trim().isNotEmpty && state.title.length <= 40;
  bool get isDescriptionValid => state.description.trim().isNotEmpty;
  bool get isValid => isTitleValid && isDescriptionValid;

  int get titleCharacterCount => state.title.length;

  // Save method
  Future<bool> save() async {
    if (!isValid) return false;

    try {
      return true;
    } catch (e) {
      // Handle error
      return false;
    }
  }
}

final editStarterPackProvider = StateNotifierProvider.family<
    EditStarterPackNotifier, StarterPackData, String>(
  (ref, starterPackId) => EditStarterPackNotifier(starterPackId),
);
