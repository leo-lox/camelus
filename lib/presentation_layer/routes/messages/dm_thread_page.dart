import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain_layer/entities/direct_message.dart';
import 'package:ndk/shared/nips/nip19/nip19.dart';
import '../../atoms/my_profile_picture.dart';
import '../../components/dm/dm_message_bubble.dart';
import '../../providers/dm_thread_provider.dart';
import '../../providers/metadata_state_provider.dart';

/// Page displaying a single DM conversation thread.
class DmThreadPage extends ConsumerStatefulWidget {
  /// The peer identifier (can be hex, npub, or nprofile)
  final String peerIdentifier;

  const DmThreadPage({super.key, required this.peerIdentifier});

  @override
  ConsumerState<DmThreadPage> createState() => _DmThreadPageState();
}

class _DmThreadPageState extends ConsumerState<DmThreadPage> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _messageFocusNode = FocusNode();
  final FlutterListViewController _scrollController =
      FlutterListViewController();

  /// Decoded hex pubkey from the identifier
  late final String _peerPubkey;

  @override
  void initState() {
    super.initState();
    _peerPubkey = _decodeIdentifier(widget.peerIdentifier);
  }

  /// Decode hex, npub, or nprofile to hex pubkey
  String _decodeIdentifier(String identifier) {
    // Already hex (64 chars)
    if (identifier.length == 64 && !identifier.startsWith('n')) {
      return identifier;
    }

    // nprofile format
    if (identifier.startsWith('nprofile')) {
      final nprofile = Nip19.decodeNprofile(identifier);
      return nprofile.pubkey;
    }

    // npub format (or other NIP-19)
    if (identifier.startsWith('npub')) {
      return Nip19.decode(identifier);
    }

    // Fallback: assume hex
    return identifier;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmThreadProvider(_peerPubkey));
    final metadataState = ref.watch(metadataStateProvider(_peerPubkey));
    final metadata = metadataState.userMetadata;

    final displayName =
        metadata?.name ?? metadata?.name ?? '${_peerPubkey.substring(0, 8)}...';

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(
            PhosphorIcons.arrowLeft(),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.push('/nostr/profile/$_peerPubkey'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserImage(
                  imageUrl: metadata?.picture,
                  pubkey: _peerPubkey,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (metadata?.nip05 != null)
                        Text(
                          metadata!.nip05!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList(context, state)),
          _buildMessageInput(context, state),
        ],
      ),
    );
  }

  Widget _buildMessageList(BuildContext context, DmThreadState state) {
    if (state.isLoading && state.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError && state.messages.isEmpty) {
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
            ),
          ],
        ),
      );
    }

    if (state.messages.isEmpty) {
      return _buildEmptyThreadState(context);
    }

    // Group messages with date separators + end of history marker
    final messagesWithSeparators = _buildMessageListWithSeparators(
      state.messages,
    );
    // Add 1 for the "beginning of conversation" or "load more" indicator
    final totalCount = messagesWithSeparators.length + 1;

    return FlutterListView(
      controller: _scrollController,
      reverse: true,
      delegate: FlutterListViewDelegate((context, index) {
        // Last item (visually at top when scrolled) is the beginning/load more indicator
        if (index == messagesWithSeparators.length) {
          return _buildEndOfHistoryIndicator(context, state);
        }

        final item = messagesWithSeparators[index];
        if (item is int) {
          // Date separator
          return DmDateSeparator(timestamp: item);
        } else {
          // Message
          return DmMessageBubble(message: item as DirectMessage);
        }
      }, childCount: totalCount),
    );
  }

  List<dynamic> _buildMessageListWithSeparators(List<DirectMessage> messages) {
    if (messages.isEmpty) return [];

    // Messages are sorted ascending by createdAt, we reverse for display
    final reversed = messages.reversed.toList();
    final result = <dynamic>[];
    int? lastDateKey;

    for (final message in reversed) {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(
        message.createdAt * 1000,
      );
      final dateKey =
          dateTime.year * 10000 + dateTime.month * 100 + dateTime.day;

      if (lastDateKey != dateKey) {
        // Insert date separator after (below in reversed list) the first message of a new day
        if (result.isNotEmpty) {
          result.add(message.createdAt);
        }
        lastDateKey = dateKey;
      }

      result.add(message);
    }

    return result;
  }

  Widget _buildEndOfHistoryIndicator(
    BuildContext context,
    DmThreadState state,
  ) {
    // Loading older messages
    if (state.isLoadingOlder) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Reached the beginning
    if (state.hasReachedBeginning) {
      return _buildBeginningOfConversation(context);
    }

    // Show "Load more" button
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: TextButton.icon(
          onPressed: () {
            ref
                .read(dmThreadProvider(_peerPubkey).notifier)
                .loadOlderMessages();
          },
          icon: Icon(PhosphorIcons.arrowUp()),
          label: const Text('Load older messages'),
        ),
      ),
    );
  }

  Widget _buildBeginningOfConversation(BuildContext context) {
    final metadataState = ref.watch(metadataStateProvider(_peerPubkey));
    final metadata = metadataState.userMetadata;
    final displayName = metadata?.name ?? '${_peerPubkey.substring(0, 8)}...';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          UserImage(imageUrl: metadata?.picture, pubkey: _peerPubkey, size: 64),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                PhosphorIcons.lock(),
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'End-to-end encrypted',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'This is the beginning of your conversation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyThreadState(BuildContext context) {
    final metadataState = ref.watch(metadataStateProvider(_peerPubkey));
    final metadata = metadataState.userMetadata;
    final displayName =
        metadata?.name ?? metadata?.name ?? '${_peerPubkey.substring(0, 8)}...';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UserImage(
              imageUrl: metadata?.picture,
              pubkey: _peerPubkey,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start your encrypted conversation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.lock(),
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'End-to-end encrypted with NIP-17',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context, DmThreadState state) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: InputDecoration(
                hintText: 'Message...',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: 5,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: state.isSending ? null : _sendMessage,
            icon: state.isSending
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Icon(
                    PhosphorIcons.paperPlaneTilt(PhosphorIconsStyle.fill),
                    color: Theme.of(context).colorScheme.primary,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    final success = await ref
        .read(dmThreadProvider(_peerPubkey).notifier)
        .sendMessage(content);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
