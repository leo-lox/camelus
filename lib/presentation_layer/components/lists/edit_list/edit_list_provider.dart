import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/nostr_list_provider.dart';
import '../../../providers/user_lists_provider.dart';

class ListData {
  final String name;
  final int kind;
  final String title;
  final String? description;
  final String? imageUrl;
  final bool imageUploading;
  final List<String> selectedItems;
  final bool broadcasting;
  final bool broadcasted;

  const ListData({
    required this.name,
    required this.kind,
    required this.title,
    this.description,
    this.imageUrl,
    required this.imageUploading,
    required this.selectedItems,
    required this.broadcasting,
    required this.broadcasted,
  });

  ListData copyWith({
    String? name,
    int? kind,
    String? title,
    String? description,
    String? imageUrl,
    bool? imageUploading,
    List<String>? selectedItems,
    bool? broadcasting,
    bool? broadcasted,
  }) {
    return ListData(
      name: name ?? this.name,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUploading: imageUploading ?? this.imageUploading,
      selectedItems: selectedItems ?? this.selectedItems,
      broadcasting: broadcasting ?? this.broadcasting,
      broadcasted: broadcasted ?? this.broadcasted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ListData) return false;
    if (other.title != title) return false;
    if (other.description != description) return false;
    if (other.imageUrl != imageUrl) return false;
    if (other.imageUploading != imageUploading) return false;
    if (other.broadcasting != broadcasting) return false;
    if (other.broadcasted != broadcasted) return false;
    if (other.selectedItems.length != selectedItems.length) return false;
    for (var i = 0; i < selectedItems.length; i++) {
      if (other.selectedItems[i] != selectedItems[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    title,
    description,
    imageUrl,
    imageUploading,
    broadcasting,
    broadcasted,
    Object.hashAll(selectedItems),
  );
}

class EditListNotifier extends Notifier<ListData> {
  late final ListIdentifier identifier;
  bool _primed = false;

  EditListNotifier(this.identifier);

  @override
  ListData build() {
    // Attempt to load synchronously from cached provider value
    final asyncLists = ref.read(userListsProvider(identifier.kind));
    final initial = asyncLists.value
        ?.where((l) => l.name == identifier.name)
        .firstOrNull;

    if (initial != null) {
      _primed = true;
      return _fromExisting(initial);
    }

    // Listen for the stream to deliver data later (e.g. cold start / deep link)
    ref.listen<AsyncValue<List<NostrSet>>>(userListsProvider(identifier.kind), (
      _,
      next,
    ) {
      if (_primed) return;
      next.whenData((lists) {
        final existing = lists
            .where((l) => l.name == identifier.name)
            .firstOrNull;
        if (existing != null) {
          _primed = true;
          state = _fromExisting(existing);
        } else {
          _primed = true; // new list – nothing to load
        }
      });
    });

    return ListData(
      name: identifier.name,
      kind: identifier.kind,
      title: '',
      description: null,
      imageUrl: null,
      imageUploading: false,
      selectedItems: const [],
      broadcasting: false,
      broadcasted: false,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ListData _fromExisting(NostrSet list) {
    return ListData(
      name: list.name,
      kind: list.kind,
      title: list.title ?? '',
      description: list.description,
      imageUrl: list.image,
      imageUploading: false,
      selectedItems: _extractItems(list),
      broadcasting: false,
      broadcasted: false,
    );
  }

  List<String> _extractItems(NostrSet list) {
    if (list.kind == NostrList.followSet ||
        list.kind == NostrList.starterPack) {
      return list.pubKeys.map((e) => e.value).toList();
    }
    if (list.kind == NostrList.curationSet) {
      return list.threads.map((e) => e.value).toList();
    }
    return [];
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  void updateTitle(String title) => state = state.copyWith(title: title);

  void updateDescription(String description) =>
      state = state.copyWith(description: description);

  void updateImage({required bool imageUploading, String? imageUrl}) => state =
      state.copyWith(imageUploading: imageUploading, imageUrl: imageUrl);

  void addItem(String value) {
    if (state.selectedItems.contains(value)) return;
    state = state.copyWith(selectedItems: [value, ...state.selectedItems]);
  }

  void removeItem(String value) {
    final updated = List<String>.from(state.selectedItems)..remove(value);
    state = state.copyWith(selectedItems: updated);
  }

  void reorderItem(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex -= 1;
    final items = List<String>.from(state.selectedItems);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(selectedItems: items);
  }

  bool get isTitleValid =>
      state.title.trim().isNotEmpty && state.title.length <= 40;

  int get titleCharacterCount => state.title.length;

  // ── Broadcast ─────────────────────────────────────────────────────────────

  Future<bool> broadcast() async {
    if (!isTitleValid) return false;

    state = state.copyWith(broadcasting: true);

    final ndk = ref.read(ndkProvider);
    final pubKey = ndk.accounts.getPublicKey();
    if (pubKey == null) {
      state = state.copyWith(broadcasting: false);
      return false;
    }

    final tag =
        (state.kind == NostrList.followSet ||
            state.kind == NostrList.starterPack)
        ? 'p'
        : 'e';
    final elements = state.selectedItems
        .map((item) => NostrListElement(tag: tag, value: item, private: false))
        .toList();

    final list = NostrSet(
      name: state.name,
      title: state.title,
      description: state.description,
      image: state.imageUrl,
      pubKey: pubKey,
      kind: state.kind,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      elements: elements,
    );

    await ref.read(nostrListProvider).broadcastList(list: list);

    state = state.copyWith(broadcasting: false, broadcasted: true);
    return true;
  }

  Future<void> deleteList() async {
    await ref
        .read(nostrListProvider)
        .deleteList(name: state.name, kind: state.kind);
  }

  void reset() {
    state = state.copyWith(broadcasted: false, broadcasting: false);
  }
}

final editListProvider =
    NotifierProvider.family<EditListNotifier, ListData, ListIdentifier>(
      EditListNotifier.new,
    );
