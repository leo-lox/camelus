import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:ndk/shared/nips/nip19/nip19.dart';
import '../../components/dm/dm_conversation_tile.dart';
import '../../providers/dm_conversations_provider.dart';
import '../../providers/ndk_provider.dart';

/// Page displaying the list of DM conversations.
class DmListPage extends ConsumerStatefulWidget {
  const DmListPage({super.key});

  @override
  ConsumerState<DmListPage> createState() => _DmListPageState();
}

class _DmListPageState extends ConsumerState<DmListPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial fetch when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(dmConversationsProvider);
      if (!state.initialFetchDone) {
        ref.read(dmConversationsProvider.notifier).fetchMessages();
      }
    });
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
                PhosphorIcons.userCircle(),
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

    final state = ref.watch(dmConversationsProvider);

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
              PhosphorIcons.pencilSimpleLine(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => context.push('/messages/new'),
            tooltip: AppLocalizations.of(context)!.newMessage,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dmConversationsProvider.notifier).refresh(),
        child: _buildBody(context, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, DmConversationsState state) {
    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.warning(),
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

    if (state.conversations.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      itemCount: state.conversations.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        indent: 82,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, index) {
        final conversation = state.conversations[index];
        final nprofile = Nip19.encodeNprofile(pubkey: conversation.peerPubkey);
        return DmConversationTile(
          conversation: conversation,
          onTap: () => context.push('/messages/$nprofile'),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.chatCircle(),
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.noMessagesYet,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.startConversationHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
