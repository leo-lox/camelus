import 'package:camelus/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain_layer/entities/direct_message.dart';
import '../../../domain_layer/entities/dm_conversation.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/metadata_state_provider.dart';

/// A tile displaying a DM conversation in the conversations list.
class DmConversationTile extends ConsumerWidget {
  final DmConversation conversation;
  final VoidCallback onTap;

  const DmConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadataState = ref.watch(
      metadataStateProvider(conversation.peerPubkey),
    );
    final metadata = metadataState.userMetadata;

    final displayName =
        metadata?.name ?? Helpers.shortHr(conversation.peerPubkey);

    return ListTile(
      onTap: onTap,
      leading: UserImage(
        imageUrl: metadata?.picture,
        pubkey: conversation.peerPubkey,
        size: 50,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            Helpers.formatTimeAgo(conversation.lastMessageAt),
            style: TextStyle(
              fontSize: 12,
              color: conversation.unreadCount > 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (conversation.lastMessageIsOutgoing)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildSendStatusIcon(context),
            ),
          Expanded(
            child: Text(
              conversation.lastMessagePreview,
              style: TextStyle(
                color: conversation.unreadCount > 0
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: conversation.unreadCount > 0
                    ? FontWeight.w500
                    : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (conversation.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.unreadCount > 99
                    ? '99+'
                    : conversation.unreadCount.toString(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildSendStatusIcon(BuildContext context) {
    final lastMessage = conversation.lastMessage;
    final sendStatus = lastMessage?.sendStatus ?? MessageSendStatus.sent;

    switch (sendStatus) {
      case MessageSendStatus.pending:
        return Icon(
          PhosphorIcons.circleDashed(),
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
      case MessageSendStatus.failed:
        return Icon(
          PhosphorIcons.xCircle(),
          size: 14,
          color: Theme.of(context).colorScheme.error,
        );
      case MessageSendStatus.sent:
        return Icon(
          PhosphorIcons.checkCircle(),
          size: 14,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    }
  }
}
