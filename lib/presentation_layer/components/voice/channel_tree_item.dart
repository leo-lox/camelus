import 'package:flutter/material.dart';
import '../../../domain_layer/entities/voice/voice_channel.dart';

/// Widget for displaying a single channel in the tree
class ChannelTreeItem extends StatelessWidget {
  final VoiceChannel channel;
  final bool isActive;
  final int depth;
  final VoidCallback? onTap;

  const ChannelTreeItem({
    Key? key,
    required this.channel,
    required this.isActive,
    this.depth = 0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: channel.isFull ? null : onTap,
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (depth * 20.0),
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            color: isActive ? theme.primaryColor.withOpacity(0.1) : null,
            child: Row(
              children: [
                Icon(
                  channel.isLocked ? Icons.lock : Icons.volume_up,
                  size: 20,
                  color: channel.isFull ? Colors.grey : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        channel.name,
                        style: TextStyle(
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: channel.isFull ? Colors.grey : null,
                        ),
                      ),
                      if (channel.description != null)
                        Text(
                          channel.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${channel.userCount}/${channel.maxUsers}',
                  style: TextStyle(
                    fontSize: 12,
                    color: channel.isFull ? Colors.red : Colors.grey,
                  ),
                ),
                if (channel.hasChildren)
                  const Icon(Icons.chevron_right, size: 16),
              ],
            ),
          ),
        ),
        // Render children
        if (channel.hasChildren)
          ...channel.children.map((child) => ChannelTreeItem(
                channel: child,
                isActive: false, // Will be determined by parent
                depth: depth + 1,
                onTap: onTap,
              )),
      ],
    );
  }
}
