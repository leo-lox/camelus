import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../components/lists/list_card.dart';
import '../../../providers/ndk_provider.dart';
import '../../../providers/user_lists_provider.dart';
import '../../../routing/route_paths.dart';

const _uuid = Uuid();

class ListsPage extends ConsumerWidget {
  const ListsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followLists = ref.watch(userListsProvider(NostrList.followSet));
    final curationLists = ref.watch(userListsProvider(NostrList.curationSet));

    final isLoading = followLists.isLoading && curationLists.isLoading;

    final allLists = [...followLists.value ?? [], ...curationLists.value ?? []]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.lists),
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.plus()),
            tooltip: AppLocalizations.of(context)!.createNewList,
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : allLists.isEmpty
          ? _EmptyListsState(onCreateTap: () => _showCreateDialog(context, ref))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: allLists.length,
              itemBuilder: (context, index) {
                final list = allLists[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ListCard(
                    list: list,
                    onTap: () => context.push(
                      RoutePaths.listEdit(kind: list.kind, name: list.name),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final ndk = ref.read(ndkProvider);
    if (ndk.accounts.getPublicKey() == null) return;

    final kind = await showDialog<int>(
      context: context,
      builder: (ctx) => _SelectListTypeDialog(),
    );
    if (kind == null) return;
    if (!context.mounted) return;

    final name = _uuid.v4();
    context.push(RoutePaths.listEdit(kind: kind, name: name, isNew: true));
  }
}

// ── Select list type dialog ────────────────────────────────────────────────

class _SelectListTypeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.selectListType),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(PhosphorIcons.users()),
            title: Text(AppLocalizations.of(context)!.followSetKind),
            onTap: () => Navigator.of(context).pop(NostrList.followSet),
          ),
          ListTile(
            leading: Icon(PhosphorIcons.newspaper()),
            title: Text(AppLocalizations.of(context)!.curationSetKind),
            onTap: () => Navigator.of(context).pop(NostrList.curationSet),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
      ],
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────

class _EmptyListsState extends StatelessWidget {
  final VoidCallback onCreateTap;
  const _EmptyListsState({required this.onCreateTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.listBullets(),
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noListsYet,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.createYourFirstList,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateTap,
            icon: const Icon(Icons.add),
            label: Text(AppLocalizations.of(context)!.createNewList),
          ),
        ],
      ),
    );
  }
}
