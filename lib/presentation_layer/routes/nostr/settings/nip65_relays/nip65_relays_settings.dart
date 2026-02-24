import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../providers/messaging/nip65_relay_settings_provider.dart';

class Nip65RelaysSettings extends ConsumerStatefulWidget {
  const Nip65RelaysSettings({super.key});

  @override
  ConsumerState<Nip65RelaysSettings> createState() =>
      _Nip65RelaysSettingsState();
}

class _Nip65RelaysSettingsState extends ConsumerState<Nip65RelaysSettings> {
  final TextEditingController _inboxRelayController = TextEditingController();
  final TextEditingController _outboxRelayController = TextEditingController();
  String? _inboxErrorText;
  String? _outboxErrorText;

  @override
  void dispose() {
    _inboxRelayController.dispose();
    _outboxRelayController.dispose();
    super.dispose();
  }

  Future<void> _addInboxRelay() async {
    final result = await ref
        .read(nip65RelaySettingsProvider.notifier)
        .addInboxRelay(_inboxRelayController.text);
    _handleAddResult(result, isInbox: true);
  }

  Future<void> _addOutboxRelay() async {
    final result = await ref
        .read(nip65RelaySettingsProvider.notifier)
        .addOutboxRelay(_outboxRelayController.text);
    _handleAddResult(result, isInbox: false);
  }

  void _handleAddResult(AddNip65RelayResult result, {required bool isInbox}) {
    final l10n = AppLocalizations.of(context)!;

    switch (result) {
      case AddNip65RelayResult.success:
        if (isInbox) {
          _inboxRelayController.clear();
          setState(() => _inboxErrorText = null);
        } else {
          _outboxRelayController.clear();
          setState(() => _outboxErrorText = null);
        }
        break;
      case AddNip65RelayResult.invalidUrl:
        setState(() {
          if (isInbox) {
            _inboxErrorText = l10n.invalidUrl;
          } else {
            _outboxErrorText = l10n.invalidUrl;
          }
        });
        break;
      case AddNip65RelayResult.alreadyExists:
        setState(() {
          if (isInbox) {
            _inboxErrorText = l10n.alreadyExists;
          } else {
            _outboxErrorText = l10n.alreadyExists;
          }
        });
        break;
      case AddNip65RelayResult.saveFailed:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.failedToSaveRelays)));
        break;
    }
  }

  void _clearInboxError() {
    if (_inboxErrorText != null) {
      setState(() => _inboxErrorText = null);
    }
  }

  void _clearOutboxError() {
    if (_outboxErrorText != null) {
      setState(() => _outboxErrorText = null);
    }
  }

  Future<void> _removeInboxRelay(String relayUrl) async {
    final success = await ref
        .read(nip65RelaySettingsProvider.notifier)
        .removeInboxRelay(relayUrl);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSaveRelays),
        ),
      );
    }
  }

  Future<void> _removeOutboxRelay(String relayUrl) async {
    final success = await ref
        .read(nip65RelaySettingsProvider.notifier)
        .removeOutboxRelay(relayUrl);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToSaveRelays),
        ),
      );
    }
  }

  String _formatCreatedAt(BuildContext context, int? createdAt) {
    if (createdAt == null) {
      return '—';
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
    final state = ref.watch(nip65RelaySettingsProvider);

    final inboxRelays =
        state.relays.entries
            .where((entry) => entry.value.isRead)
            .map((entry) => entry.key)
            .toList()
          ..sort();

    final outboxRelays =
        state.relays.entries
            .where((entry) => entry.value.isWrite)
            .map((entry) => entry.key)
            .toList()
          ..sort();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft()),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('${AppLocalizations.of(context)!.relays} (NIP-65)'),
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
            onPressed: state.isSaving
                ? null
                : () => ref
                      .read(nip65RelaySettingsProvider.notifier)
                      .fetchRelays(),
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: Column(
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
                  PhosphorIcons.info(),
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'NIP-65 relay hints for your account. Inbox relays are read relays, outbox relays are write relays. Changes are saved immediately.',
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
                'Last sync: ${_formatCreatedAt(context, state.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildRelaySection(
                  context: context,
                  title: 'Inbox relays',
                  relays: inboxRelays,
                  controller: _inboxRelayController,
                  errorText: _inboxErrorText,
                  isSaving: state.isSaving,
                  onChanged: _clearInboxError,
                  onSubmitted: _addInboxRelay,
                  onAdd: _addInboxRelay,
                  onRemove: _removeInboxRelay,
                ),
                const SizedBox(height: 20),
                _buildRelaySection(
                  context: context,
                  title: 'Outbox relays',
                  relays: outboxRelays,
                  controller: _outboxRelayController,
                  errorText: _outboxErrorText,
                  isSaving: state.isSaving,
                  onChanged: _clearOutboxError,
                  onSubmitted: _addOutboxRelay,
                  onAdd: _addOutboxRelay,
                  onRemove: _removeOutboxRelay,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelaySection({
    required BuildContext context,
    required String title,
    required List<String> relays,
    required TextEditingController controller,
    required String? errorText,
    required bool isSaving,
    required VoidCallback onChanged,
    required Future<void> Function() onSubmitted,
    required Future<void> Function() onAdd,
    required Future<void> Function(String relayUrl) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'wss://relay.example.com',
                  errorText: errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmitted(),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: isSaving ? null : onAdd,
              icon: Icon(PhosphorIcons.plus()),
              tooltip: AppLocalizations.of(context)!.addRelay,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (relays.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: Text(
              'No relays configured',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          ...relays.map(
            (relay) => _buildRelayTile(context, relay, isSaving, onRemove),
          ),
      ],
    );
  }

  Widget _buildRelayTile(
    BuildContext context,
    String relay,
    bool isSaving,
    Future<void> Function(String relayUrl) onRemove,
  ) {
    final displayUrl = relay
        .replaceAll('wss://', '')
        .replaceAll('ws://', '')
        .replaceAll('/', '');

    return ListTile(
      contentPadding: EdgeInsets.zero,
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
        onPressed: isSaving ? null : () => onRemove(relay),
        tooltip: AppLocalizations.of(context)!.removeRelay,
      ),
    );
  }
}
