import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain_layer/entities/voice/voice_server.dart';
import '../../../domain_layer/entities/voice/voice_room.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/voice/voice_provider.dart';

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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${room.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice communication is currently in beta.'),
            const SizedBox(height: 8),
            Text('Make sure you have granted microphone permissions.'),
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
              // TODO: Implement actual voice connection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Voice connection coming soon!'),
                ),
              );
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }
}
