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
            'Messages',
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
                'Please login to view messages',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/onboarding'),
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(dmConversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              PhosphorIcons.pencilSimpleLine(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () => _showNewMessageDialog(context),
            tooltip: 'New message',
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
              state.errorMessage ?? 'Failed to load messages',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(dmConversationsProvider.notifier).fetchMessages(),
              child: const Text('Retry'),
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
              'No messages yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by tapping the pencil icon',
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

  void _showNewMessageDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Message'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the pubkey (nprofile, npub, or hex):'),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'nprofile1..., npub1..., or hex',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final input = textController.text.trim();
              if (input.isEmpty) return;

              String hexPubkey;

              // Decode input to hex pubkey
              if (input.startsWith('nprofile')) {
                final decoded = Nip19.decodeNprofile(input);
                hexPubkey = decoded.pubkey;
              } else if (input.startsWith('npub')) {
                hexPubkey = Nip19.decode(input);
              } else {
                hexPubkey = input; // Assume hex
              }

              // Create nprofile for navigation
              final nprofile = Nip19.encodeNprofile(pubkey: hexPubkey);

              Navigator.of(context).pop();
              context.push('/messages/$nprofile');
            },
            child: const Text('Start Chat'),
          ),
        ],
      ),
    );
  }
}
