import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../domain_layer/entities/voice/voice_server.dart';
import '../../../domain_layer/entities/voice/voice_room.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/voice/voice_provider.dart';
import '../../providers/voice/livekit_provider.dart';
import '../../providers/ndk_provider.dart';

class VoiceServerPage extends ConsumerStatefulWidget {
  final VoiceServer server;

  const VoiceServerPage({super.key, required this.server});

  @override
  ConsumerState<VoiceServerPage> createState() => _VoiceServerPageState();
}

class _VoiceServerPageState extends ConsumerState<VoiceServerPage> {
  @override
  void initState() {
    super.initState();
    // Load rooms when page opens
    Future.microtask(() {
      ref.read(voiceRoomsProvider(widget.server.address).notifier).loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceRoomsProvider(widget.server.address));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.server.name),
            Text(
              widget.server.address,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.arrowsClockwise()),
            onPressed: () {
              ref.read(voiceRoomsProvider(widget.server.address).notifier).loadRooms();
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.warningCircle(),
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(state.error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(voiceRoomsProvider(widget.server.address).notifier).loadRooms();
                        },
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                )
              : state.rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            PhosphorIcons.speakerSlash(),
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rooms available',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.rooms.length,
                      itemBuilder: (context, index) {
                        final room = state.rooms[index];
                        return _buildRoomCard(context, room);
                      },
                    ),
    );
  }

  Widget _buildRoomCard(BuildContext context, VoiceRoom room) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(
          room.isFull ? PhosphorIcons.lockKey() : PhosphorIcons.speakerHigh(),
          color: room.isFull
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          room.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(room.description),
            const SizedBox(height: 4),
            Text(
              '${room.userCount}/${room.maxUsers} users',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: room.isFull
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: room.isFull
              ? null
              : () {
                  _showJoinRoomDialog(context, room);
                },
          icon: Icon(PhosphorIcons.signIn(), size: 16),
          label: const Text('Join'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        children: [
          if (room.users.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Users in room:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...room.users.map((user) => _buildUserTile(context, user)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserTile(BuildContext context, VoiceUser user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            user.isMuted
                ? PhosphorIcons.microphoneSlash()
                : PhosphorIcons.microphone(),
            size: 16,
            color: user.isMuted
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (user.role == 'admin')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ADMIN',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog(BuildContext context, VoiceRoom room) {
    final voiceConnection = ref.read(voiceConnectionProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (voiceConnection.isConnected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'You are currently connected to another room. Joining will disconnect you.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            const Text('Voice communication will start immediately.'),
            const SizedBox(height: 8),
            const Text('Make sure you have granted microphone permissions.'),
            const SizedBox(height: 8),
            Text(
              'Server: ${widget.server.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Room: ${room.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinRoom(context, room);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinRoom(BuildContext context, VoiceRoom room) async {
    final voiceConnectionNotifier = ref.read(voiceConnectionProvider.notifier);
    final liveKitService = ref.read(liveKitVoiceServiceProvider);
    final ndk = ref.read(ndkProvider);
    
    try {
      voiceConnectionNotifier.setConnecting(true);
      
      // Show loading
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting to voice room...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Get user info
      final userPubkey = ndk.accounts.getPublicKey();
      final userId = userPubkey ?? 'anon-${DateTime.now().millisecondsSinceEpoch}';
      final displayName = 'User'; // TODO: Get from user profile

      // Request token from server
      final tokenResponse = await http.post(
        Uri.parse('http://${widget.server.address}/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'roomId': room.id,
          'userId': userId,
          'displayName': displayName,
        }),
      );

      if (tokenResponse.statusCode != 200) {
        throw Exception('Failed to get access token: ${tokenResponse.statusCode}');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final token = tokenData['token'] as String;
      final livekitUrl = tokenData['url'] as String;

      // Connect to LiveKit
      await liveKitService.connect(
        url: livekitUrl,
        token: token,
        roomName: room.id,
      );

      voiceConnectionNotifier.setConnected(
        true,
        roomId: room.id,
        serverUrl: widget.server.address,
      );

      if (!context.mounted) return;
      
      // Show voice controls dialog
      _showVoiceControlsDialog(context, room, liveKitService);
      
    } catch (e) {
      voiceConnectionNotifier.setError(e.toString());
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to join room: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _showVoiceControlsDialog(BuildContext context, VoiceRoom room, dynamic service) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Consumer(
          builder: (context, ref, _) {
            final voiceConnection = ref.watch(voiceConnectionProvider);
            
            return AlertDialog(
              title: Row(
                children: [
                  Icon(PhosphorIcons.microphone(), color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(child: Text(room.name)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    voiceConnection.isConnected ? 'Connected' : 'Connecting...',
                    style: TextStyle(
                      color: voiceConnection.isConnected 
                          ? Colors.green 
                          : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        iconSize: 48,
                        onPressed: () async {
                          await service.toggleMute();
                          ref.read(voiceConnectionProvider.notifier).setMuted(service.isMuted);
                        },
                        icon: Icon(
                          voiceConnection.isMuted 
                              ? PhosphorIcons.microphoneSlash() 
                              : PhosphorIcons.microphone(),
                          color: voiceConnection.isMuted 
                              ? Theme.of(context).colorScheme.error 
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    voiceConnection.isMuted ? 'Muted' : 'Unmuted',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await service.disconnect();
                    ref.read(voiceConnectionProvider.notifier).disconnect();
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: Icon(PhosphorIcons.phoneDisconnect()),
                  label: const Text('Leave Room'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
