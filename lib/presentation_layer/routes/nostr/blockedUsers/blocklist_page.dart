import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ndk/ndk.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../providers/metadata_state_provider.dart';
import '../../../providers/moderation/blocklist_provider.dart';

class BlocklistPage extends ConsumerStatefulWidget {
  const BlocklistPage({super.key});

  @override
  ConsumerState<BlocklistPage> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<BlocklistPage> {
  final TextEditingController _wordController = TextEditingController();

  String _formatSyncedListCreatedAt(BuildContext context, DateTime createdAt) {
    final localCreatedAt = createdAt.toLocal();
    final diff = DateTime.now().difference(localCreatedAt);
    if (diff <= const Duration(hours: 24)) {
      return "${timeago.format(localCreatedAt, locale: 'en_short')} ago";
    }

    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).add_Hm().format(localCreatedAt);
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(blocklistNotifierProvider.notifier).sync();
    });
  }

  @override
  void dispose() {
    _wordController.dispose();
    super.dispose();
  }

  Future<void> _addWord() async {
    final word = _wordController.text.trim();
    if (word.isEmpty) {
      return;
    }

    await ref.read(blocklistNotifierProvider.notifier).blockWord(word);
    if (mounted) {
      _wordController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocklistState = ref.watch(blocklistNotifierProvider);
    final blocklistNotifier = ref.read(blocklistNotifierProvider.notifier);
    final syncedCreatedAt = blocklistState.syncedListCreatedAt;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.blockedUsers),
        actions: [
          if (syncedCreatedAt != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  _formatSyncedListCreatedAt(context, syncedCreatedAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          IconButton(
            onPressed: blocklistState.isLoading
                ? null
                : () => blocklistNotifier.sync(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.blockedUsers,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (blocklistState.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (blocklistState.blockedPubkeys.isEmpty)
            Text(
              'No blocked users',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            )
          else
            ...blocklistState.blockedPubkeys.map((pubkey) {
              final metadata = ref.watch(metadataStateProvider(pubkey));
              final displayName =
                  metadata.userMetadata?.name ?? metadata.userMetadata?.nip05;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_off),
                title: Text(displayName ?? Nip19.encodePubKey(pubkey)),
                subtitle: displayName == null
                    ? null
                    : Text(
                        Nip19.encodePubKey(pubkey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: blocklistState.isLoading
                      ? null
                      : () => blocklistNotifier.unblockPubkey(pubkey),
                ),
              );
            }),
          const Divider(height: 32),
          Text(
            AppLocalizations.of(context)!.hideWords,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _wordController,
                  enabled: !blocklistState.isLoading,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addWord(),
                  decoration: const InputDecoration(
                    hintText: 'Add blocked word',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: blocklistState.isLoading ? null : _addWord,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (blocklistState.blockedWords.isEmpty)
            Text(
              'No blocked words',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: blocklistState.blockedWords
                  .map(
                    (word) => Chip(
                      label: Text(word),
                      onDeleted: blocklistState.isLoading
                          ? null
                          : () => blocklistNotifier.unblockWord(word),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}
