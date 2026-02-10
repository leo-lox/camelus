import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain_layer/entities/voice/voice_channel.dart';
import '../../providers/voice/voice_connection_provider.dart';
import '../../providers/voice/voice_servers_provider.dart';
import '../../providers/voice/voice_channels_provider.dart';
import '../../components/voice/channel_tree_view.dart';
import '../../components/voice/user_list_item.dart';

class VoiceChannelsPage extends ConsumerStatefulWidget {
  const VoiceChannelsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<VoiceChannelsPage> createState() => _VoiceChannelsPageState();
}

class _VoiceChannelsPageState extends ConsumerState<VoiceChannelsPage> {
  @override
  Widget build(BuildContext context) {
    final connectionData = ref.watch(voiceConnectionProvider);
    final server = ref.watch(selectedVoiceServerProvider);
    final channelsAsync = ref.watch(channelTreeProvider);
    final currentChannel = ref.watch(currentChannelProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(server?.name ?? 'Voice Chat'),
        actions: [
          // Connection status indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildConnectionStatus(connectionData.state),
          ),
        ],
      ),
      body: _buildBody(context, connectionData, channelsAsync, currentChannel),
      bottomNavigationBar: _buildVoiceControls(context, connectionData),
    );
  }

  Widget _buildConnectionStatus(VoiceConnectionState state) {
    final color = switch (state) {
      VoiceConnectionState.connected => Colors.green,
      VoiceConnectionState.connecting ||
      VoiceConnectionState.initializing => Colors.orange,
      VoiceConnectionState.error => Colors.red,
      _ => Colors.grey,
    };

    final icon = switch (state) {
      VoiceConnectionState.connected => Icons.check_circle,
      VoiceConnectionState.connecting ||
      VoiceConnectionState.initializing => Icons.sync,
      VoiceConnectionState.error => Icons.error,
      _ => Icons.radio_button_unchecked,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(state.name, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _buildBody(
    BuildContext context,
    VoiceConnectionData connectionData,
    AsyncValue<List<VoiceChannel>> channelsAsync,
    dynamic currentChannel,
  ) {
    if (connectionData.state == VoiceConnectionState.error) {
      return _buildErrorView(connectionData.error);
    }

    if (connectionData.state == VoiceConnectionState.initializing ||
        connectionData.state == VoiceConnectionState.connecting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to voice server...'),
          ],
        ),
      );
    }

    if (connectionData.state == VoiceConnectionState.connected) {
      return Row(
        children: [
          // Channel tree (left side)
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.folder_open, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Channels',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () {
                            ref.invalidate(channelTreeProvider);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: channelsAsync.when(
                      data: (channels) {
                        if (channels.isEmpty) {
                          return const Center(
                            child: Text(
                              'No channels available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          );
                        }

                        return ChannelTreeView(
                          channels: channels,
                          currentChannelId:
                              currentChannel?.id ?? connectionData.channelId,
                          onChannelTap: (channel) {
                            // TODO: Implement channel switching
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Switching to ${channel.name} not yet implemented',
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(height: 8),
                            Text('Error loading channels: $error'),
                            TextButton(
                              onPressed: () {
                                ref.invalidate(channelTreeProvider);
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // User list (right side)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.people, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildUserList(
                    currentChannel?.id ?? connectionData.channelId,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const Center(child: Text('Not connected'));
  }

  Widget _buildErrorView(String? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Connection Error'),
          const SizedBox(height: 8),
          Text(
            error ?? 'Unknown error',
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final server = ref.read(selectedVoiceServerProvider);
              if (server != null) {
                ref.read(voiceConnectionProvider.notifier).connect(server);
              }
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(String? channelId) {
    final users = ref.watch(channelUsersProvider(channelId));

    if (channelId == null) {
      return const Center(
        child: Text('Select a channel', style: TextStyle(color: Colors.grey)),
      );
    }

    if (users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'No users in this channel',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final userPubkey = users[index];
        return UserListItem(
          pubkey: userPubkey,
          isSpeaking: false, // TODO: Implement voice activity detection
          isMuted: false, // TODO: Get from server state
          isDeafened: false,
        );
      },
    );
  }

  Widget _buildVoiceControls(
    BuildContext context,
    VoiceConnectionData connectionData,
  ) {
    final isMuted = ref.watch(isMutedProvider);
    final isDeafened = ref.watch(isDeafenedProvider);

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            IconButton(
              icon: Icon(isMuted ? Icons.mic_off : Icons.mic, size: 32),
              color: isMuted ? Colors.red : Colors.green,
              onPressed: connectionData.state == VoiceConnectionState.connected
                  ? () {
                      ref.read(voiceConnectionProvider.notifier).toggleMute();
                    }
                  : null,
              tooltip: isMuted ? 'Unmute' : 'Mute',
            ),

            // Deafen button
            IconButton(
              icon: Icon(
                isDeafened ? Icons.headset_off : Icons.headset,
                size: 32,
              ),
              color: isDeafened ? Colors.red : Colors.green,
              onPressed: connectionData.state == VoiceConnectionState.connected
                  ? () {
                      ref.read(isDeafenedProvider.notifier).state = !isDeafened;
                    }
                  : null,
              tooltip: isDeafened ? 'Undeafen' : 'Deafen',
            ),

            // Disconnect button
            IconButton(
              icon: const Icon(Icons.call_end, size: 32),
              color: Colors.red,
              onPressed:
                  connectionData.state != VoiceConnectionState.disconnected
                  ? () async {
                      await ref
                          .read(voiceConnectionProvider.notifier)
                          .disconnect();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  : null,
              tooltip: 'Disconnect',
            ),
          ],
        ),
      ),
    );
  }
}
