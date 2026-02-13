import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/voice_chat/voice_chat_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../../domain_layer/entities/voice_chat/voice_channel.dart';
import '../../../domain_layer/entities/voice_chat/voice_user.dart';

class VoiceChatPage extends ConsumerStatefulWidget {
  const VoiceChatPage({super.key});

  @override
  ConsumerState<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends ConsumerState<VoiceChatPage> {
  final TextEditingController _serverUrlController = TextEditingController();

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  void _connect() {
    final serverUrl = _serverUrlController.text.trim();
    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a server URL')),
      );
      return;
    }

    final npub = ref.read(ndkProvider).accounts.getPublicKey();
    ref.read(voiceChatProvider.notifier).connect(serverUrl, npub);
  }

  void _disconnect() {
    ref.read(voiceChatProvider.notifier).disconnect();
  }

  @override
  Widget build(BuildContext context) {
    final voiceChatState = ref.watch(voiceChatProvider);
    final isConnected = voiceChatState.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Chat'),
        actions: [
          if (isConnected)
            IconButton(
              icon: Icon(PhosphorIcons.signOut()),
              onPressed: _disconnect,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: isConnected
          ? _buildConnectedView(voiceChatState)
          : _buildConnectionView(),
    );
  }

  Widget _buildConnectionView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            PhosphorIcons.microphoneStage(),
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Connect to Voice Server',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _serverUrlController,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'ws://localhost:8080',
              border: const OutlineInputBorder(),
              prefixIcon: Icon(PhosphorIcons.globe()),
            ),
            onSubmitted: (_) => _connect(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _connect,
            icon: Icon(PhosphorIcons.plugsConnected()),
            label: const Text('Connect'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(VoiceChatState voiceChatState) {
    final rootChannels = voiceChatState.channelState.getChildChannels(null);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Channels',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    children: rootChannels.map((channel) {
                      return _buildChannelTree(channel, voiceChatState);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: _buildCurrentChannelView(voiceChatState),
        ),
      ],
    );
  }

  Widget _buildChannelTree(VoiceChannel channel, VoiceChatState voiceChatState) {
    final childChannels = voiceChatState.channelState.getChildChannels(channel.id);
    final usersInChannel = voiceChatState.channelState.getUsersInChannel(channel.id);
    final isCurrentChannel = voiceChatState.channelState.currentChannelId == channel.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(
            childChannels.isEmpty
                ? PhosphorIcons.speakerHigh()
                : PhosphorIcons.folder(),
            size: 20,
          ),
          title: Text(channel.name),
          trailing: usersInChannel.isNotEmpty
              ? CircleAvatar(
                  radius: 12,
                  child: Text(
                    usersInChannel.length.toString(),
                    style: const TextStyle(fontSize: 10),
                  ),
                )
              : null,
          selected: isCurrentChannel,
          onTap: () {
            ref.read(voiceChatProvider.notifier).joinChannel(channel.id);
          },
        ),
        if (childChannels.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              children: childChannels.map((child) {
                return _buildChannelTree(child, voiceChatState);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentChannelView(VoiceChatState voiceChatState) {
    final currentChannelId = voiceChatState.channelState.currentChannelId;
    if (currentChannelId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.chatCircle(),
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a channel to join',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }

    final channel = voiceChatState.channelState.channels.firstWhere(
      (c) => c.id == currentChannelId,
      orElse: () => VoiceChannel(id: '', name: '', position: 0),
    );

    final usersInChannel = voiceChatState.channelState.getUsersInChannel(currentChannelId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(PhosphorIcons.speakerHigh()),
              const SizedBox(width: 8),
              Text(
                channel.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            itemCount: usersInChannel.length,
            itemBuilder: (context, index) {
              final user = usersInChannel[index];
              return _buildUserTile(user);
            },
          ),
        ),
        _buildControlBar(voiceChatState),
      ],
    );
  }

  Widget _buildUserTile(VoiceUser user) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            child: Text(
              user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
            ),
          ),
          if (user.isSpeaking)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(user.displayName ?? user.npub ?? 'Anonymous'),
      subtitle: Text(user.group.name),
      trailing: user.isMuted
          ? Icon(PhosphorIcons.microphoneSlash(), size: 20)
          : null,
    );
  }

  Widget _buildControlBar(VoiceChatState voiceChatState) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filled(
            icon: Icon(PhosphorIcons.microphoneSlash()),
            onPressed: () {
              ref.read(voiceChatProvider.notifier).toggleMute();
            },
            iconSize: 24,
            tooltip: 'Toggle Mute',
          ),
          const SizedBox(width: 16),
          IconButton.filled(
            icon: Icon(PhosphorIcons.phoneDisconnect()),
            onPressed: _disconnect,
            iconSize: 24,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            tooltip: 'Disconnect',
          ),
        ],
      ),
    );
  }
}
