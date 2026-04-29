import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/nostr_list.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/user_lists_provider.dart';
import '../../routing/route_paths.dart';

class WalletFriendsStrip extends ConsumerWidget {
  const WalletFriendsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myPubkey = ref.read(ndkProvider).accounts.getPublicKey();
    final listsAsync = ref.watch(userListsProvider(NostrList.followSet));

    final friendsSet = listsAsync.value
        ?.where((s) => s.name == NostrList.friendsSetName)
        .firstOrNull;

    final editPath = RoutePaths.listEdit(
      kind: NostrList.followSet,
      name: NostrList.friendsSetName,
      isNew: friendsSet == null,
      defaultTitle: friendsSet == null ? 'Friends' : null,
    );

    return Container(
      width: MediaQuery.of(context).size.width,
      height: 130,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 4, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    friendsSet?.title ?? 'Friends',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 2, 15, 6),
              child: listsAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : myPubkey == null || friendsSet == null
                  ? _EmptyCta(editPath: editPath)
                  : _FriendsList(
                      pubkeys: friendsSet.pubKeys.map((e) => e.value).toList(),
                      editPath: editPath,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / no-list state ─────────────────────────────────────────────────────

class _EmptyCta extends StatelessWidget {
  final String editPath;
  const _EmptyCta({required this.editPath});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      onTap: () => context.push(editPath),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            radius: 30,
            child: const Icon(Icons.add),
          ),
          const SizedBox(width: 12),
          Text(
            "Add friends",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Populated friends list ────────────────────────────────────────────────────

class _FriendsList extends StatelessWidget {
  final List<String> pubkeys;
  final String editPath;
  const _FriendsList({required this.pubkeys, required this.editPath});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...pubkeys.map((pk) => _FriendAvatarItem(pubkey: pk)),
          const SizedBox(width: 10),
          _AddButton(editPath: editPath),
        ],
      ),
    );
  }
}

// ── Single friend avatar ──────────────────────────────────────────────────────

class _FriendAvatarItem extends ConsumerWidget {
  final String pubkey;
  const _FriendAvatarItem({required this.pubkey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = ref.watch(metadataStateProvider(pubkey)).userMetadata;
    final displayName = meta?.name ?? pubkey.substring(0, 8);

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        onTap: () => context.push(RoutePaths.profile(pubkey: pubkey)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            UserImage(imageUrl: meta?.picture, pubkey: pubkey, size: 50),
            const SizedBox(height: 2),
            SizedBox(
              width: 60,
              child: Text(
                displayName,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "+" add button ────────────────────────────────────────────────────────────

class _AddButton extends StatelessWidget {
  final String editPath;
  const _AddButton({required this.editPath});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: const BorderRadius.all(Radius.circular(50)),
      onTap: () => context.push(editPath),
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        radius: 25,
        child: const Icon(Icons.add),
      ),
    );
  }
}
