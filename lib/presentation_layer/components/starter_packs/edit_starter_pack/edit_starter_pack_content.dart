import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/nip_05_text.dart';
import '../../../providers/search_provider.dart';
import '../../../routes/search_page.dart';
import '../../search_bar.dart';
import 'edit_starter_pack_provider.dart';

class EditStarterPackContent extends ConsumerStatefulWidget {
  final String starterPackId;
  final Function onNext;
  const EditStarterPackContent({
    super.key,
    required this.starterPackId,
    required this.onNext,
  });
  @override
  ConsumerState<EditStarterPackContent> createState() =>
      _EditStarterPackContentState();
}

class _EditStarterPackContentState
    extends ConsumerState<EditStarterPackContent> {
  _addToSelection(UserMetadata user) {
    final starterPackNotifier =
        ref.read(editStarterPackProvider(widget.starterPackId).notifier);

    starterPackNotifier.addUser(user);
  }

  _removeFromSelection(UserMetadata user) {
    final starterPackNotifier =
        ref.read(editStarterPackProvider(widget.starterPackId).notifier);

    starterPackNotifier.removeUser(user);
  }

  @override
  Widget build(BuildContext context) {
    final searchService = ref.read(searchProvider);
    final searchState = ref.watch(searchStateProvider);
    final searchNotifier = ref.watch(searchStateProvider.notifier);
    final starterPackData =
        ref.watch(editStarterPackProvider(widget.starterPackId));
    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
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
            },
            onSubmit: (value) {},
            helpSearch: (context) {},
            onBackPress: () {
              searchNotifier.clearSearch();
            },
          ),
          Expanded(
              child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              ...searchState.searchResultsUsers.map((user) {
                final selected = starterPackData.selectedUsers.contains(user);
                return PersonSelect(
                  user: user,
                  selected: selected,
                  onTab: () => selected
                      ? _removeFromSelection(user)
                      : _addToSelection(user),
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
                  );
                }),
              if (starterPackData.selectedUsers.isEmpty)
                Center(
                  heightFactor: 5,
                  child: Text("start searching to add user"),
                )
            ],
          ))
        ],
      ),
    );
  }
}

class PersonSelect extends StatelessWidget {
  final UserMetadata user;
  final bool selected;
  final Function onTab;
  const PersonSelect({
    super.key,
    required this.user,
    required this.selected,
    required this.onTab,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => onTab(),
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
      trailing: Icon(
        selected ? PhosphorIcons.checkCircle() : PhosphorIcons.circle(),
        color: Palette.white,
      ),
    );
  }
}
