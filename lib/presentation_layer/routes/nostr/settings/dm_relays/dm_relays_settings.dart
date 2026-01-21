import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../providers/dm_relay_list_provider.dart';

/// Settings page for managing DM relays (kind 10050)
class DmRelaysSettings extends ConsumerStatefulWidget {
  const DmRelaysSettings({super.key});

  @override
  ConsumerState<DmRelaysSettings> createState() => _DmRelaysSettingsState();
}

class _DmRelaysSettingsState extends ConsumerState<DmRelaysSettings> {
  final TextEditingController _relayController = TextEditingController();

  @override
  void dispose() {
    _relayController.dispose();
    super.dispose();
  }

  Future<void> _addRelay() async {
    final url = _relayController.text.trim();
    if (url.isEmpty) return;

    final success = await ref.read(dmRelayListProvider.notifier).addRelay(url);

    if (success) {
      _relayController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relay added')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add relay (may already exist)')),
        );
      }
    }
  }

  Future<void> _removeRelay(String relayUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Relay'),
        content: Text('Remove $relayUrl from your DM relays?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Remove',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(dmRelayListProvider.notifier).removeRelay(relayUrl);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relay removed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmRelayListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('DM Relays'),
        actions: [
          if (state.isLoading || state.isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise()),
            onPressed: state.isLoading
                ? null
                : () => ref.read(dmRelayListProvider.notifier).fetchRelays(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.info(),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These relays are used specifically for sending and receiving private messages (NIP-17). Other users will send DMs to these relays.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add relay input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _relayController,
                    decoration: InputDecoration(
                      hintText: 'wss://relay.example.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _addRelay(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: state.isSaving ? null : _addRelay,
                  icon: Icon(PhosphorIcons.plus()),
                  tooltip: 'Add relay',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Relay list
          Expanded(
            child: state.relays.isEmpty
                ? _buildEmptyState(context, state)
                : ListView.builder(
                    itemCount: state.relays.length,
                    itemBuilder: (context, index) {
                      final relay = state.relays[index];
                      return _buildRelayTile(context, relay, state.isSaving);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DmRelayListState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.chatCircleDots(),
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No DM relays configured',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add relays where you want to receive private messages. Without DM relays, your NIP-65 inbox relays will be used as fallback.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Suggested relays
            Text(
              'Suggested relays:',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSuggestedRelay('wss://auth.nostr1.com'),
                _buildSuggestedRelay('wss://relay.0xchat.com'),
                _buildSuggestedRelay('wss://inbox.nostr.wine'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedRelay(String url) {
    return ActionChip(
      label: Text(url.replaceAll('wss://', '').replaceAll('/', '')),
      onPressed: () {
        _relayController.text = url;
        _addRelay();
      },
    );
  }

  Widget _buildRelayTile(BuildContext context, String relay, bool isSaving) {
    // Extract domain for display
    final displayUrl = relay
        .replaceAll('wss://', '')
        .replaceAll('ws://', '')
        .replaceAll('/', '');

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          PhosphorIcons.globe(),
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        displayUrl,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        relay,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          PhosphorIcons.trash(),
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: isSaving ? null : () => _removeRelay(relay),
        tooltip: 'Remove relay',
      ),
    );
  }
}
