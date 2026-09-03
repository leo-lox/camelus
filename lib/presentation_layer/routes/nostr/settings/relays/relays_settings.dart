import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/domain_layer/entities/feed_filter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../../../providers/generic_feed_provider.dart';
import '../../../../providers/messaging/dm_relay_list_provider.dart';
import '../../../../providers/ndk_provider.dart';
import '../../../../providers/messaging/nip65_relay_settings_provider.dart';

class Nip65RelaysSettings extends ConsumerStatefulWidget {
  const Nip65RelaysSettings({super.key});

  @override
  ConsumerState<Nip65RelaysSettings> createState() =>
      _Nip65RelaysSettingsState();
}

class _Nip65RelaysSettingsState extends ConsumerState<Nip65RelaysSettings> {
  final TextEditingController _nip65RelayController = TextEditingController();
  final TextEditingController _dmRelayController = TextEditingController();
  String? _nip65ErrorText;
  String? _dmErrorText;

  @override
  void dispose() {
    _nip65RelayController.dispose();
    _dmRelayController.dispose();
    super.dispose();
  }

  bool get _hasUnsavedChanges {
    final nip65State = ref.read(nip65RelaySettingsProvider);
    final dmState = ref.read(dmRelayListProvider);
    return nip65State.hasChanges || dmState.hasChanges;
  }

  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasUnsavedChanges) {
      return true;
    }

    final l10n = AppLocalizations.of(context)!;
    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChanges),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Future<void> _onBackPressed() async {
    final shouldLeave = await _showUnsavedChangesDialog();
    if (shouldLeave && mounted) {
      _discardLocalChanges();
      Navigator.of(context).pop();
    }
  }

  void _discardLocalChanges() {
    ref.read(nip65RelaySettingsProvider.notifier).discardChanges();
    ref.read(dmRelayListProvider.notifier).discardChanges();
  }

  void _clearNip65Error() {
    if (_nip65ErrorText != null) {
      setState(() => _nip65ErrorText = null);
    }
  }

  void _clearDmError() {
    if (_dmErrorText != null) {
      setState(() => _dmErrorText = null);
    }
  }

  void _addNip65Relay() {
    final notifier = ref.read(nip65RelaySettingsProvider.notifier);
    final result = notifier.addRelay(_nip65RelayController.text);
    final l10n = AppLocalizations.of(context)!;

    switch (result) {
      case AddNip65RelayResult.success:
        _nip65RelayController.clear();
        setState(() => _nip65ErrorText = null);
        break;
      case AddNip65RelayResult.invalidUrl:
        setState(() => _nip65ErrorText = l10n.invalidUrl);
        break;
      case AddNip65RelayResult.alreadyExists:
        setState(() => _nip65ErrorText = l10n.alreadyExists);
        break;
      case AddNip65RelayResult.saveFailed:
        setState(() => _nip65ErrorText = l10n.failedToSaveRelays);
        break;
    }
  }

  void _removeNip65Relay(String relayUrl) {
    ref.read(nip65RelaySettingsProvider.notifier).removeRelay(relayUrl);
  }

  void _setNip65Permissions(
    String relayUrl, {
    required bool isRead,
    required bool isWrite,
  }) {
    ref
        .read(nip65RelaySettingsProvider.notifier)
        .setRelayPermissions(relayUrl, isRead: isRead, isWrite: isWrite);
  }

  void _addDmRelay() {
    final url = _dmRelayController.text.trim();
    if (url.isEmpty) {
      return;
    }

    final result = ref.read(dmRelayListProvider.notifier).addRelay(url);
    final l10n = AppLocalizations.of(context)!;

    switch (result) {
      case AddRelayResult.success:
        _dmRelayController.clear();
        setState(() => _dmErrorText = null);
        break;
      case AddRelayResult.invalidUrl:
        setState(() => _dmErrorText = l10n.invalidUrl);
        break;
      case AddRelayResult.alreadyExists:
        setState(() => _dmErrorText = l10n.alreadyExists);
        break;
    }
  }

  void _removeDmRelay(String relayUrl) {
    ref.read(dmRelayListProvider.notifier).removeRelay(relayUrl);
  }

  void _restoreDmRelay(String relayUrl) {
    ref.read(dmRelayListProvider.notifier).restoreRelay(relayUrl);
  }

  Future<void> _saveChanges() async {
    final l10n = AppLocalizations.of(context)!;
    final nip65State = ref.read(nip65RelaySettingsProvider);
    final dmState = ref.read(dmRelayListProvider);

    var success = true;

    if (nip65State.hasChanges) {
      final nip65Saved = await ref
          .read(nip65RelaySettingsProvider.notifier)
          .saveChanges();
      success = success && nip65Saved;
    }

    if (dmState.hasChanges) {
      final dmSaved = await ref
          .read(dmRelayListProvider.notifier)
          .saveChanges();
      success = success && dmSaved;
    }

    if (!mounted) {
      return;
    }

    if (success) {
      _invalidateUserGenericFeed();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? l10n.changesSavedSuccessfully : l10n.failedToSaveChanges,
        ),
      ),
    );
  }

  void _invalidateUserGenericFeed() {
    final myPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    if (myPubkey == null) {
      return;
    }

    final feedIdSuffix = myPubkey.length > 20
        ? myPubkey.substring(10, 20)
        : myPubkey;

    ref.invalidate(
      genericFeedStateProvider(
        FeedFilter(
          authors: [myPubkey],
          kinds: [1, 6],
          feedId: 'profile-$feedIdSuffix',
          showRootNotesOnly: true,
        ),
      ),
    );
    ref.invalidate(
      genericFeedStateProvider(
        FeedFilter(
          authors: [myPubkey],
          kinds: [1, 6],
          feedId: 'profile-$feedIdSuffix',
          showRootNotesOnly: false,
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    final nip65State = ref.read(nip65RelaySettingsProvider);
    final dmState = ref.read(dmRelayListProvider);

    if (nip65State.hasChanges || dmState.hasChanges) {
      return;
    }

    await Future.wait([
      ref.read(nip65RelaySettingsProvider.notifier).fetchRelays(),
      ref.read(dmRelayListProvider.notifier).fetchRelays(),
    ]);
  }

  String _formatCreatedAt(BuildContext context, int? createdAt) {
    if (createdAt == null) {
      return '-';
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      createdAt * 1000,
      isUtc: true,
    ).toLocal();

    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatMediumDate(dateTime);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    return '$date $time';
  }

  @override
  Widget build(BuildContext context) {
    final nip65State = ref.watch(nip65RelaySettingsProvider);
    final dmState = ref.watch(dmRelayListProvider);
    final l10n = AppLocalizations.of(context)!;

    final nip65Relays = nip65State.relays.keys.toList()..sort();

    final newDmRelays = dmState.relays
        .where((relay) => !dmState.originalRelays.contains(relay))
        .toList();
    final allDmRelays = [...dmState.originalRelays, ...newDmRelays];

    final hasUnsavedChanges = nip65State.hasChanges || dmState.hasChanges;
    final isSaving = nip65State.isSaving || dmState.isSaving;
    final isLoading = nip65State.isLoading || dmState.isLoading;

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }

        final shouldLeave = await _showUnsavedChangesDialog();
        if (shouldLeave && mounted) {
          _discardLocalChanges();
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          leading: IconButton(
            icon: Icon(PhosphorIcons.arrowLeft),
            onPressed: _onBackPressed,
          ),
          title: Text(l10n.relays),
          actions: [
            if (isLoading || isSaving)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (hasUnsavedChanges && !isSaving)
              TextButton(
                onPressed: _saveChanges,
                child: Text(l10n.saveChanges),
              ),
            IconButton(
              icon: Icon(PhosphorIcons.arrowClockwise),
              onPressed: (isSaving || hasUnsavedChanges) ? null : _refreshAll,
              tooltip: l10n.refresh,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.info,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NIP-65 relays define read/write hints for your account. DM relays are used for private messages.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last sync: ${_formatCreatedAt(context, nip65State.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'NIP-65 Relays',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nip65RelayController,
                      decoration: InputDecoration(
                        hintText: 'wss://relay.example.com',
                        errorText: _nip65ErrorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => _clearNip65Error(),
                      onSubmitted: (_) => _addNip65Relay(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: isSaving ? null : _addNip65Relay,
                    icon: Icon(PhosphorIcons.plus),
                    tooltip: l10n.addRelay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (nip65Relays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    l10n.noRelaysFound,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...nip65Relays.map(
                (relay) => _buildNip65RelayTile(
                  context,
                  relay,
                  nip65State.relays[relay]!,
                  isSaving,
                ),
              ),
            const SizedBox(height: 20),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                l10n.dmRelays,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Last sync: ${_formatCreatedAt(context, dmState.lastSyncedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dmRelayController,
                      decoration: InputDecoration(
                        hintText: 'wss://relay.example.com',
                        errorText: _dmErrorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => _clearDmError(),
                      onSubmitted: (_) => _addDmRelay(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: isSaving ? null : _addDmRelay,
                    icon: Icon(PhosphorIcons.plus),
                    tooltip: l10n.addRelay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (allDmRelays.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                  child: Text(
                    l10n.noDmRelaysConfigured,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              ...allDmRelays.map(
                (relay) => _buildDmRelayTile(
                  context,
                  relay,
                  isSaving,
                  !dmState.relays.contains(relay),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNip65RelayTile(
    BuildContext context,
    String relay,
    dynamic marker,
    bool isSaving,
  ) {
    final displayUrl = relay
        .replaceAll('wss://', '')
        .replaceAll('ws://', '')
        .replaceAll('/', '');

    final isRead = marker.isRead as bool;
    final isWrite = marker.isWrite as bool;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          PhosphorIcons.globe,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        displayUrl,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              selected: isRead,
              onSelected: isSaving
                  ? null
                  : (value) => _setNip65Permissions(
                      relay,
                      isRead: value,
                      isWrite: isWrite,
                    ),
              label: Text(AppLocalizations.of(context)!.read),
            ),
            FilterChip(
              selected: isWrite,
              onSelected: isSaving
                  ? null
                  : (value) => _setNip65Permissions(
                      relay,
                      isRead: isRead,
                      isWrite: value,
                    ),
              label: Text(AppLocalizations.of(context)!.write),
            ),
          ],
        ),
      ),
      trailing: IconButton(
        icon: Icon(
          PhosphorIcons.trash,
          color: Theme.of(context).colorScheme.error,
        ),
        onPressed: isSaving ? null : () => _removeNip65Relay(relay),
        tooltip: AppLocalizations.of(context)!.removeRelay,
      ),
    );
  }

  Widget _buildDmRelayTile(
    BuildContext context,
    String relay,
    bool isSaving,
    bool isPendingDeletion,
  ) {
    final displayUrl = relay
        .replaceAll('wss://', '')
        .replaceAll('ws://', '')
        .replaceAll('/', '');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
          PhosphorIcons.globe,
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
              ? PhosphorIcons.arrowCounterClockwise
              : PhosphorIcons.trash,
          color: isPendingDeletion
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        onPressed: isSaving
            ? null
            : () => isPendingDeletion
                  ? _restoreDmRelay(relay)
                  : _removeDmRelay(relay),
        tooltip: isPendingDeletion
            ? AppLocalizations.of(context)!.restoreRelay
            : AppLocalizations.of(context)!.removeRelay,
      ),
    );
  }
}
