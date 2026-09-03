import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:ndk/shared/nips/nip19/nip19.dart';
import '../../../domain_layer/entities/dm_conversation.dart';
import '../../atoms/my_profile_picture.dart';
import '../../components/dm/dm_conversation_tile.dart';
import '../../providers/messaging/dm_categories_provider.dart';
import '../../providers/messaging/dm_conversations_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';

/// Page displaying the list of DM conversations with category tabs.
class DmListPage extends ConsumerStatefulWidget {
  const DmListPage({super.key});

  @override
  ConsumerState<DmListPage> createState() => _DmListPageState();
}

class _DmListPageState extends ConsumerState<DmListPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Trigger initial fetch when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(dmConversationsProvider);
      if (!state.initialFetchDone) {
        ref.read(dmConversationsProvider.notifier).fetchMessages();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();

    // Not logged in
    if (currentUserPubkey == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            AppLocalizations.of(context)!.messages,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.userCircle,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.pleaseLoginToViewMessages,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/onboarding'),
                child: Text(AppLocalizations.of(context)!.login),
              ),
            ],
          ),
        ),
      );
    }

    final categorizedState = ref.watch(dmCategoriesProvider);
    final conversationsState = ref.watch(dmConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          AppLocalizations.of(context)!.messages,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.pencilSimpleLine,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.push('/messages/new'),
            tooltip: AppLocalizations.of(context)!.newMessage,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          splashFactory: NoSplash.splashFactory,
          tabs: [
            _buildTab(
              context,
              AppLocalizations.of(context)!.dmFollows,
              categorizedState.getUnreadCount(DmCategory.follows),
            ),
            _buildTab(
              context,
              AppLocalizations.of(context)!.dmKnown,
              categorizedState.getUnreadCount(DmCategory.known),
            ),
            _buildTab(
              context,
              AppLocalizations.of(context)!.dmRequests,
              categorizedState.getUnreadCount(DmCategory.requests),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dmConversationsProvider.notifier).refresh(),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildFollowsTab(context, categorizedState, conversationsState),
            _buildKnownTab(context, categorizedState, conversationsState),
            _buildRequestsTab(context, categorizedState, conversationsState),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(BuildContext context, String label, int unreadCount) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (unreadCount > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFollowsTab(
    BuildContext context,
    CategorizedDmState categorizedState,
    DmConversationsState conversationsState,
  ) {
    if (conversationsState.isLoading &&
        categorizedState.follows.isEmpty &&
        categorizedState.noteToSelf == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationsState.hasError && categorizedState.follows.isEmpty) {
      return _buildErrorState(context, conversationsState);
    }

    final myPubkey = ref.read(ndkProvider).accounts.getPublicKey()!;
    final conversations = categorizedState.follows;

    if (conversations.isEmpty) {
      return _buildEmptyState(
        context,
        AppLocalizations.of(context)!.noFollowsConversations,
        showNoteToSelf: true,
        myPubkey: myPubkey,
        noteToSelf: categorizedState.noteToSelf,
      );
    }

    // Always show Note to Self tile at the top
    return ListView.separated(
      itemCount: conversations.length + 1,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 82,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _NoteToSelfTile(
            conversation: categorizedState.noteToSelf,
            myPubkey: myPubkey,
          );
        }

        final conversation = conversations[index - 1];
        final nprofile = Nip19.encodeNprofile(pubkey: conversation.peerPubkey);
        return DmConversationTile(
          conversation: conversation,
          onTap: () => context.push('/messages/$nprofile'),
        );
      },
    );
  }

  Widget _buildKnownTab(
    BuildContext context,
    CategorizedDmState categorizedState,
    DmConversationsState conversationsState,
  ) {
    if (conversationsState.isLoading && categorizedState.known.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationsState.hasError && categorizedState.known.isEmpty) {
      return _buildErrorState(context, conversationsState);
    }

    final conversations = categorizedState.known;

    if (conversations.isEmpty) {
      return _buildEmptyState(
        context,
        AppLocalizations.of(context)!.noKnownConversations,
      );
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 82,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final nprofile = Nip19.encodeNprofile(pubkey: conversation.peerPubkey);
        return DmConversationTile(
          conversation: conversation,
          onTap: () => context.push('/messages/$nprofile'),
        );
      },
    );
  }

  Widget _buildRequestsTab(
    BuildContext context,
    CategorizedDmState categorizedState,
    DmConversationsState conversationsState,
  ) {
    if (conversationsState.isLoading && categorizedState.requests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (conversationsState.hasError && categorizedState.requests.isEmpty) {
      return _buildErrorState(context, conversationsState);
    }

    final conversations = categorizedState.requests;

    if (conversations.isEmpty) {
      return _buildEmptyState(
        context,
        AppLocalizations.of(context)!.noMessageRequests,
      );
    }

    return ListView.separated(
      itemCount: conversations.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 82,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final nprofile = Nip19.encodeNprofile(pubkey: conversation.peerPubkey);
        return DmConversationTile(
          conversation: conversation,
          onTap: () => context.push('/messages/$nprofile'),
        );
      },
    );
  }

  Widget _buildErrorState(BuildContext context, DmConversationsState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.warning,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            state.errorMessage ??
                AppLocalizations.of(context)!.failedToLoadMessages,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () =>
                ref.read(dmConversationsProvider.notifier).fetchMessages(),
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    String message, {
    bool showNoteToSelf = false,
    String? myPubkey,
    DmConversation? noteToSelf,
  }) {
    if (showNoteToSelf && myPubkey != null) {
      // Show Note to Self tile at the top even when list is empty
      return Column(
        children: [
          _NoteToSelfTile(conversation: noteToSelf, myPubkey: myPubkey),
          Divider(
            height: 1,
            indent: 82,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.chatCircle,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.chatCircle,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Special tile for "Note to Self" conversation.
class _NoteToSelfTile extends ConsumerWidget {
  final DmConversation? conversation;
  final String myPubkey;

  const _NoteToSelfTile({required this.conversation, required this.myPubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMessages = conversation != null;
    final metadataState = ref.watch(metadataStateProvider(myPubkey));
    final metadata = metadataState.userMetadata;

    return ListTile(
      onTap: () {
        final nprofile = Nip19.encodeNprofile(pubkey: myPubkey);
        context.push('/messages/$nprofile');
      },
      leading: Stack(
        children: [
          UserImage(imageUrl: metadata?.picture, pubkey: myPubkey, size: 50),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                PhosphorIcons.checkBold,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 10,
              ),
            ),
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.noteToSelf,
              style: TextStyle(
                fontWeight: hasMessages && conversation!.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (hasMessages)
            Text(
              Helpers.formatTimeAgo(conversation!.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: conversation!.unreadCount > 0
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      subtitle: hasMessages
          ? Row(
              children: [
                Expanded(
                  child: Text(
                    conversation!.lastMessagePreview,
                    style: TextStyle(
                      color: conversation!.unreadCount > 0
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: conversation!.unreadCount > 0
                          ? FontWeight.w500
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (conversation!.unreadCount > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conversation!.unreadCount > 99
                          ? '99+'
                          : conversation!.unreadCount.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            )
          : Text(
              AppLocalizations.of(context)!.noteToSelfHint,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}
