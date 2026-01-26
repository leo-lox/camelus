import 'package:camelus/l10n/app_localizations.dart';
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
  String? _errorText;

  @override
  void dispose() {
    _relayController.dispose();
    super.dispose();
  }

  void _addRelay() {
    final url = _relayController.text.trim();
    if (url.isEmpty) return;

    final result = ref.read(dmRelayListProvider.notifier).addRelay(url);
    switch (result) {
      case AddRelayResult.success:
        _relayController.clear();
        setState(() => _errorText = null);
        break;
      case AddRelayResult.invalidUrl:
        setState(() => _errorText = AppLocalizations.of(context)!.invalidUrl);
        break;
      case AddRelayResult.alreadyExists:
        setState(
          () => _errorText = AppLocalizations.of(context)!.alreadyExists,
        );
        break;
    }
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
  }

  void _removeRelay(String relayUrl) {
    ref.read(dmRelayListProvider.notifier).removeRelay(relayUrl);
  }

  void _restoreRelay(String relayUrl) {
    ref.read(dmRelayListProvider.notifier).restoreRelay(relayUrl);
  }

  Future<void> _saveChanges() async {
    final success = await ref.read(dmRelayListProvider.notifier).saveChanges();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? AppLocalizations.of(context)!.relaysSaved
                : AppLocalizations.of(context)!.failedToSaveRelays,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dmRelayListProvider);

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppLocalizations.of(context)!.dmRelays),
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
          if (state.hasChanges && !state.isSaving)
            TextButton(
              onPressed: _saveChanges,
              child: Text(AppLocalizations.of(context)!.save),
            ),
          IconButton(
            icon: Icon(PhosphorIcons.arrowClockwise()),
            onPressed: state.isLoading || state.hasChanges
                ? null
                : () => ref.read(dmRelayListProvider.notifier).fetchRelays(),
            tooltip: AppLocalizations.of(context)!.refresh,
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
                    AppLocalizations.of(context)!.dmRelaysInfo,
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
                      errorText: _errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (_) => _clearError(),
                    onSubmitted: (_) => _addRelay(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: state.isSaving ? null : _addRelay,
                  icon: Icon(PhosphorIcons.plus()),
                  tooltip: AppLocalizations.of(context)!.addRelay,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // Relay list (active + pending deletion)
          Expanded(child: _buildRelayList(context, state)),
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
              AppLocalizations.of(context)!.noDmRelaysConfigured,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.dmRelaysEmptyDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Suggested relays
            Text(
              AppLocalizations.of(context)!.suggestedRelays,
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

  Widget _buildRelayList(BuildContext context, DmRelayListState state) {
    // Keep original order: original relays + newly added relays
    final newRelays = state.relays
        .where((r) => !state.originalRelays.contains(r))
        .toList();

    final allRelays = [...state.originalRelays, ...newRelays];

    if (allRelays.isEmpty) {
      return _buildEmptyState(context, state);
    }

    return ListView.builder(
      itemCount: allRelays.length,
      itemBuilder: (context, index) {
        final relay = allRelays[index];
        final isPendingDeletion = !state.relays.contains(relay);
        return _buildRelayTile(
          context,
          relay,
          state.isSaving,
          isPendingDeletion,
        );
      },
    );
  }

  Widget _buildRelayTile(
    BuildContext context,
    String relay,
    bool isSaving,
    bool isPendingDeletion,
  ) {
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
          color: isPendingDeletion
              ? Theme.of(context).colorScheme.surfaceContainerHighest
              : Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          PhosphorIcons.globe(),
          color: isPendingDeletion
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        displayUrl,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          decoration: isPendingDeletion ? TextDecoration.lineThrough : null,
          color: isPendingDeletion
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      subtitle: Text(
        relay,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          decoration: isPendingDeletion ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          isPendingDeletion
              ? PhosphorIcons.arrowCounterClockwise()
              : PhosphorIcons.trash(),
          color: isPendingDeletion
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        onPressed: isSaving
            ? null
            : () => isPendingDeletion
                  ? _restoreRelay(relay)
                  : _removeRelay(relay),
        tooltip: isPendingDeletion
            ? AppLocalizations.of(context)!.restoreRelay
            : AppLocalizations.of(context)!.removeRelay,
      ),
    );
  }
}
