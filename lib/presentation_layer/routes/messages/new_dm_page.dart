import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../components/person_card.dart';
import '../search/search_state_notifier.dart';

/// Page for starting a new DM conversation by searching for users.
class NewDmPage extends ConsumerStatefulWidget {
  const NewDmPage({super.key});

  @override
  ConsumerState<NewDmPage> createState() => _NewDmPageState();
}

class _NewDmPageState extends ConsumerState<NewDmPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchStateNotifier _searchNotifier;

  @override
  void initState() {
    super.initState();
    _searchNotifier = ref.read(searchStateProvider.notifier);
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    // Delay the provider mutation so it runs after the widget tree is finalized.
    Future(() => _searchNotifier.clearSearch());
    super.dispose();
  }

  void _onUserSelected(String pubkey) {
    final nprofile = Nip19.encodeNprofile(pubkey: pubkey);
    context.go('/messages/$nprofile');
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          l10n.newMessage,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: l10n.searchUserHint,
                prefixIcon: Icon(PhosphorIcons.magnifyingGlass),
                suffixIcon: searchState.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(PhosphorIcons.x),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchStateProvider.notifier).clearSearch();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                ref.read(searchStateProvider.notifier).setSearchQuery(value);
              },
            ),
          ),

          // Results
          Expanded(child: _buildContent(context, searchState, l10n)),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    SearchState searchState,
    AppLocalizations l10n,
  ) {
    // Empty state
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.magnifyingGlass,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.searchToStartConversation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Too short query
    if (_searchController.text.length < 2) {
      return Center(
        child: Text(
          l10n.enterAtLeast2Characters,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    // No results
    if (!searchState.isLoading && searchState.searchResultsUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.userCircle,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noUsersFound,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Results list
    return ListView.separated(
      itemCount: searchState.searchResultsUsers.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 72,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final user = searchState.searchResultsUsers[index];
        return PersonCard(
          showFollowButton: false,
          pubkey: user.pubkey,
          name: user.name ?? '',
          pictureUrl: user.picture ?? '',
          about: user.about ?? '',
          nip05: user.nip05,
          isFollowing: false,
          onTap: () => _onUserSelected(user.pubkey),
          onFollowTab: (_) {},
        );
      },
    );
  }
}
