import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../atoms/my_profile_picture.dart';
import '../../../atoms/nip_05_text.dart';
import '../../../providers/search_provider.dart';
import '../../../routes/search_page.dart';
import '../../person_card.dart';
import '../../search_bar.dart';

class EditStarterPackContent extends ConsumerStatefulWidget {
  const EditStarterPackContent({super.key});
  @override
  ConsumerState<EditStarterPackContent> createState() =>
      _EditStarterPackContentState();
}

class _EditStarterPackContentState
    extends ConsumerState<EditStarterPackContent> {
  @override
  Widget build(BuildContext context) {
    final searchService = ref.read(searchProvider);
    final searchState = ref.watch(searchStateProvider);
    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        children: [
          SearchBarWidget(
            onSearchChanged: (value) async {
              ref.read(searchStateProvider.notifier).setSearchQuery(value);

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
          ),
          Expanded(
              child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              ...searchState.searchResultsUsers
                  .map((user) => PersonSelect(user: user)),
            ],
          ))
        ],
      ),
    );
  }
}

Widget PersonSelect({required UserMetadata user}) {
  return ListTile(
    onTap: () {
      // Toggle selection
    },
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
      false ? PhosphorIcons.checkCircle() : PhosphorIcons.circle(),
      color: Palette.white,
    ),
  );
}
