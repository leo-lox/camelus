import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/user_lists_provider.dart';
import '../list_card.dart';
import 'edit_list_provider.dart';

class EditListSummary extends ConsumerWidget {
  final ListIdentifier listIdentifier;
  final VoidCallback onPublishing;

  const EditListSummary({
    super.key,
    required this.listIdentifier,
    required this.onPublishing,
  });

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx)!.deleteListConfirm),
        content: Text(AppLocalizations.of(ctx)!.deleteListMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              AppLocalizations.of(ctx)!.deleteList,
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(editListProvider(listIdentifier).notifier).deleteList();

    ref.invalidate(userListsProvider(listIdentifier.kind));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.listDeleted)),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(editListProvider(listIdentifier));
    final notifier = ref.watch(editListProvider(listIdentifier).notifier);
    final ndk = ref.watch(ndkProvider);
    final pubKey = ndk.accounts.getPublicKey()!;

    final previewList = NostrSet(
      name: data.name,
      title: data.title,
      description: data.description,
      image: data.imageUrl,
      pubKey: pubKey,
      kind: data.kind,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      elements: data.selectedItems
          .map(
            (v) => NostrListElement(
              tag: data.kind == NostrList.followSet ? 'p' : 'e',
              value: v,
              private: false,
            ),
          )
          .toList(),
    );

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 24),
                Text(
                  data.broadcasted
                      ? AppLocalizations.of(context)!.listSaved
                      : AppLocalizations.of(context)!.lists,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ListCard(list: previewList),
                const SizedBox(height: 24),
                // Delete option for existing lists
                if (!data.broadcasted)
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, ref),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.deleteList,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Action button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: data.broadcasted
                    ? longButton(
                        name: AppLocalizations.of(context)!.close,
                        inverted: false,
                        onPressed: () {
                          notifier.reset();
                          ref.invalidate(
                            userListsProvider(listIdentifier.kind),
                          );
                          context.pop();
                        },
                      )
                    : longButton(
                        name: AppLocalizations.of(context)!.publishList,
                        inverted: true,
                        loading: data.broadcasting,
                        onPressed: () async {
                          onPublishing();
                          await notifier.broadcast();
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
