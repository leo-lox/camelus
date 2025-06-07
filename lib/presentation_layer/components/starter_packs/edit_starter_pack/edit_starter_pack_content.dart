import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/starter_pack_identifier.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/nip_05_text.dart';
import '../../../providers/search_provider.dart';
import '../../../routes/search_page.dart';
import '../../search_bar.dart';
import 'edit_starter_pack_provider.dart';

class EditStarterPackContent extends ConsumerStatefulWidget {
  final StarterPackIdentifier starterPackIdentifier;
  final Function onNext;
  const EditStarterPackContent({
    super.key,
    required this.starterPackIdentifier,
    required this.onNext,
  });
  @override
  ConsumerState<EditStarterPackContent> createState() =>
      _EditStarterPackContentState();
}

class _EditStarterPackContentState
    extends ConsumerState<EditStarterPackContent> {
  bool _isReorderMode = false;

  _addToSelection(UserMetadata user) {
    final starterPackNotifier = ref
        .read(editStarterPackProvider(widget.starterPackIdentifier).notifier);

    starterPackNotifier.addUser(user);
  }

  _removeFromSelection(UserMetadata user) {
    final starterPackNotifier = ref
        .read(editStarterPackProvider(widget.starterPackIdentifier).notifier);

    starterPackNotifier.removeUser(user);
  }

  _reorderUser(int oldIndex, int newIndex) {
    final starterPackNotifier = ref
        .read(editStarterPackProvider(widget.starterPackIdentifier).notifier);

    starterPackNotifier.reorderUser(oldIndex, newIndex);
  }

  @override
  Widget build(BuildContext context) {
    final searchService = ref.read(searchProvider);
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.watch(searchStateProvider.notifier);
    final starterPackData =
        ref.watch(editStarterPackProvider(widget.starterPackIdentifier));

    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        children: [
          Column(
            children: [
              SearchBarWidget(
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
                  ref
                      .read(searchStateProvider.notifier)
                      .setSearchResultsUsers(users);

                  setState(() {
                    _isReorderMode = false;
                  });
                },
                onSubmit: (value) {},
                helpSearch: (context) {},
                trailing: IconButton(
                  icon: Icon(
                    PhosphorIcons.listNumbers(),
                    color: _isReorderMode ? Palette.primary : Palette.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isReorderMode = !_isReorderMode;
                    });
                  },
                ),
                onBackPress: () {
                  searchNotifier.clearSearch();
                },
              ),
            ],
          ),
          Expanded(
            child: _isReorderMode && starterPackData.selectedUsers.isNotEmpty
                ? _buildReorderableList(starterPackData)
                : _buildNormalList(searchState, starterPackData),
          ),
          if (!searchState.isSearching)
            Container(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SafeArea(
                top: false,
                child: SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: longButton(
                        name: starterPackData.selectedUsers.isEmpty
                            ? "add users to continue"
                            : "continue with ${starterPackData.selectedUsers.length} people",
                        inverted: true,
                        disabled: starterPackData.selectedUsers.isEmpty,
                        onPressed: () {
                          widget.onNext();
                        })),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReorderableList(StarterPackData starterPackData) {
    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: starterPackData.selectedUsers.length,
      onReorder: _reorderUser,
      buildDefaultDragHandles: false,
      itemBuilder: (context, index) {
        final user = starterPackData.selectedUsers[index];
        return PersonSelect(
          key: ValueKey(user.pubkey),
          user: user,
          selected: true,
          onTab: () => _removeFromSelection(user),
          isReorderMode: true,
          reorderIndex: index,
        );
      },
    );
  }

  Widget _buildNormalList(
      SearchState searchState, StarterPackData starterPackData) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ...searchState.searchResultsUsers.map((user) {
          final selected = starterPackData.selectedUsers.contains(user);
          return PersonSelect(
            user: user,
            selected: selected,
            onTab: () =>
                selected ? _removeFromSelection(user) : _addToSelection(user),
            isReorderMode: false,
          );
        }),
        if (!searchState.isSearching)
          ...starterPackData.selectedUsers.map((user) {
            if (searchState.searchResultsUsers.contains(user)) {
              return Container();
            }
            return PersonSelect(
              user: user,
              selected: true,
              onTab: () => _removeFromSelection(user),
              isReorderMode: false,
            );
          }),
        if (starterPackData.selectedUsers.isEmpty && !searchState.isSearching)
          const Center(
            heightFactor: 5,
            child: Text("start searching to add user"),
          )
      ],
    );
  }
}

class PersonSelect extends StatelessWidget {
  final UserMetadata user;
  final bool selected;
  final Function onTab;
  final bool isReorderMode;
  final int? reorderIndex;

  const PersonSelect({
    super.key,
    required this.user,
    required this.selected,
    required this.onTab,
    this.isReorderMode = false,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap:
          isReorderMode ? null : () => onTab(), // Disable tap in reorder mode
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserImage(
            imageUrl: user?.picture,
            pubkey: user.pubkey,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.name ?? "",
                  style: const TextStyle(
                    color: Palette.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Nip05Text(
                  pubkey: user.pubkey,
                  nip05verified: user.nip05,
                ),
                const SizedBox(height: 4),
                Text(
                  user?.about ?? "",
                  style: const TextStyle(
                    color: Palette.gray,
                    fontSize: 12,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isReorderMode)
            Icon(
              selected ? PhosphorIcons.checkCircle() : PhosphorIcons.circle(),
              color: Palette.white,
            ),
          if (isReorderMode)
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: Container(
                color: Colors.transparent,
                height: 80,
                width: 50,
                child: Icon(PhosphorIcons.dotsSixVertical()),
              ),
            )
        ],
      ),
    );
  }
}
