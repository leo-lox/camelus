import 'package:flutter/material.dart';
import '../../../domain_layer/entities/voice/voice_channel.dart';
import 'channel_tree_item.dart';

/// Widget for displaying the entire channel tree
class ChannelTreeView extends StatelessWidget {
  final List<VoiceChannel> channels;
  final String? currentChannelId;
  final Function(VoiceChannel)? onChannelTap;

  const ChannelTreeView({
    Key? key,
    required this.channels,
    this.currentChannelId,
    this.onChannelTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) {
      return const Center(
        child: Text(
          'No channels available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      children: _buildChannelTree(channels, 0),
    );
  }

  List<Widget> _buildChannelTree(List<VoiceChannel> channels, int depth) {
    final widgets = <Widget>[];

    for (final channel in channels) {
      widgets.add(
        ChannelTreeItem(
          channel: channel,
          isActive: channel.id == currentChannelId,
          depth: depth,
          onTap: () => onChannelTap?.call(channel),
        ),
      );

      // Add children recursively
      if (channel.hasChildren) {
        widgets.addAll(_buildChannelTree(channel.children, depth + 1));
      }
    }

    return widgets;
  }
}
