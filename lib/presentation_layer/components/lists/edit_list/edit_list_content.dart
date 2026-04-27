import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/search_provider.dart';
import '../../../routes/search/search_state_notifier.dart';
import '../../search_bar.dart';
import '../../starter_packs/edit_starter_pack/edit_starter_pack_content.dart';
import 'edit_list_provider.dart';

class EditListContent extends ConsumerStatefulWidget {
  final ListIdentifier listIdentifier;
  final VoidCallback onNext;

  const EditListContent({
    super.key,
    required this.listIdentifier,
    required this.onNext,
  });

  @override
  ConsumerState<EditListContent> createState() => _EditListContentState();
}

class _EditListContentState extends ConsumerState<EditListContent> {
  bool _isReorderMode = false;
  final _noteIdController = TextEditingController();
  String? _noteIdError;

  @override
  void dispose() {
    _noteIdController.dispose();
    super.dispose();
  }

  void _addItem(String value) {
    ref.read(editListProvider(widget.listIdentifier).notifier).addItem(value);
  }

  void _removeItem(String value) {
    ref
        .read(editListProvider(widget.listIdentifier).notifier)
        .removeItem(value);
  }

  void _reorderItem(int oldIndex, int newIndex) {
    ref
        .read(editListProvider(widget.listIdentifier).notifier)
        .reorderItem(oldIndex, newIndex);
  }

  /// Returns hex event ID or null if invalid.
  String? _decodeNoteId(String input) {
    final trimmed = input.trim();
    if (RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(trimmed)) {
      return trimmed.toLowerCase();
    }
    try {
      if (trimmed.startsWith('note1')) return Nip19.decode(trimmed);
      if (trimmed.startsWith('nevent1')) {
        return Nip19.decodeNevent(trimmed).eventId;
      }
    } catch (_) {}
    return null;
  }

  void _submitNoteId() {
    final eventId = _decodeNoteId(_noteIdController.text);
    if (eventId == null) {
      setState(
        () => _noteIdError = AppLocalizations.of(context)!.invalidNoteId,
      );
      return;
    }
    setState(() => _noteIdError = null);
    _addItem(eventId);
    _noteIdController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(editListProvider(widget.listIdentifier));
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.watch(searchStateProvider.notifier);
    final searchService = ref.read(searchProvider);

    final isPeopleList = widget.listIdentifier.kind == NostrList.followSet;

    return Scaffold(
      body: Column(
        children: [
          // Search / input header
          if (isPeopleList)
            _PeopleSearchHeader(
              searchNotifier: searchNotifier,
              searchService: searchService,
              isReorderMode: _isReorderMode,
              hasSelectedItems: data.selectedItems.isNotEmpty,
              onReorderToggle: () {
                setState(() => _isReorderMode = !_isReorderMode);
                if (!_isReorderMode) searchNotifier.clearSearch();
              },
            )
          else
            _NoteIdInputHeader(
              controller: _noteIdController,
              errorText: _noteIdError,
              onSubmit: _submitNoteId,
            ),

          // Main list
          Expanded(
            child: isPeopleList
                ? (_isReorderMode && data.selectedItems.isNotEmpty
                      ? _buildPeopleReorderList(data)
                      : _buildPeopleNormalList(searchState, data))
                : _buildNotesList(data),
          ),

          // Continue button (hidden while searching people)
          if (!searchState.isSearching || !isPeopleList)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: longButton(
                    name: data.selectedItems.isEmpty
                        ? AppLocalizations.of(context)!.addUsersToContinue
                        : AppLocalizations.of(
                            context,
                          )!.continueWithPeople(data.selectedItems.length),
                    inverted: true,
                    disabled: data.selectedItems.isEmpty,
                    onPressed: widget.onNext,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeopleReorderList(ListData data) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: data.selectedItems.length,
      onReorder: _reorderItem,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final pubkey = data.selectedItems[index];
        return PersonSelect(
          key: ValueKey(pubkey),
          pubkey: pubkey,
          selected: true,
          onTab: () => _removeItem(pubkey),
          isReorderMode: true,
          reorderIndex: index,
        );
      },
    );
  }

  Widget _buildPeopleNormalList(SearchState searchState, ListData data) {
    final selectedSet = data.selectedItems.toSet();
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ...searchState.searchResultsUsers.map((user) {
          final selected = selectedSet.contains(user.pubkey);
          return PersonSelect(
            key: ValueKey(user.pubkey),
            pubkey: user.pubkey,
            selected: selected,
            onTab: () =>
                selected ? _removeItem(user.pubkey) : _addItem(user.pubkey),
            isReorderMode: false,
          );
        }),
        if (!searchState.isSearching)
          ...data.selectedItems
              .where(
                (pubkey) => !searchState.searchResultsUsers.any(
                  (u) => u.pubkey == pubkey,
                ),
              )
              .map((pubkey) {
                return PersonSelect(
                  key: ValueKey(pubkey),
                  pubkey: pubkey,
                  selected: true,
                  onTab: () => _removeItem(pubkey),
                  isReorderMode: false,
                );
              }),
        if (data.selectedItems.isEmpty && !searchState.isSearching)
          _EmptyPeopleState(),
      ],
    );
  }

  Widget _buildNotesList(ListData data) {
    if (data.selectedItems.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.pasteNoteId,
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: data.selectedItems.length,
      itemBuilder: (context, index) {
        final eventId = data.selectedItems[index];
        return _NoteItem(
          key: ValueKey(eventId),
          eventId: eventId,
          onRemove: () => _removeItem(eventId),
        );
      },
    );
  }
}

// ── People search header ─────────────────────────────────────────────────────

class _PeopleSearchHeader extends ConsumerWidget {
  final SearchStateNotifier searchNotifier;
  final dynamic searchService;
  final bool isReorderMode;
  final bool hasSelectedItems;
  final VoidCallback onReorderToggle;

  const _PeopleSearchHeader({
    required this.searchNotifier,
    required this.searchService,
    required this.isReorderMode,
    required this.hasSelectedItems,
    required this.onReorderToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SearchBarWidget(
      onSearchChanged: (value) async {
        searchNotifier.setSearchQuery(value);
        searchNotifier.setSearching(true);
        if (value.isEmpty) {
          ref
              .read(searchStateProvider.notifier)
              .clearSearch(stillSearching: false);
          return;
        }
        final users = await searchService.searchMetadata(value);
        ref.read(searchStateProvider.notifier).setSearchResultsUsers(users);
      },
      onSubmit: (_) {},
      helpSearch: (_) {},
      trailing: IconButton(
        icon: Icon(
          PhosphorIcons.listNumbers(),
          color: isReorderMode
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: onReorderToggle,
      ),
      onBackPress: () => searchNotifier.clearSearch(),
    );
  }
}

// ── Note ID input header ────────────────────────────────────────────────────

class _NoteIdInputHeader extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final VoidCallback onSubmit;

  const _NoteIdInputHeader({
    required this.controller,
    this.errorText,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.pasteNoteId,
                errorText: errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(onPressed: onSubmit, icon: const Icon(Icons.add)),
        ],
      ),
    );
  }
}

// ── Note item tile ──────────────────────────────────────────────────────────

class _NoteItem extends StatelessWidget {
  final String eventId;
  final VoidCallback onRemove;

  const _NoteItem({super.key, required this.eventId, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final short =
        '${eventId.substring(0, 8)}…${eventId.substring(eventId.length - 6)}';
    return ListTile(
      leading: const Icon(Icons.article_outlined),
      title: Text(
        short,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.remove_circle_outline,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: onRemove,
      ),
    );
  }
}

// ── Empty state for people lists ────────────────────────────────────────────

class _EmptyPeopleState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      heightFactor: 5,
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.searchToAddUser,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            AppLocalizations.of(context)!.addUserMenuHint,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          ),
        ],
      ),
    );
  }
}
