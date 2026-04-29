import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../domain_layer/entities/nostr_list.dart';
import '../../../helpers/helpers.dart';
import '../../atoms/spinner_center.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/nostr_list_provider.dart';
import '../../providers/nostr_lists_follow_state_provider.dart';
import '../../routing/route_paths.dart';

class StarterPackSelectionBottomSheet extends ConsumerStatefulWidget {
  final String userPubkey; // The user to be added to the pack
  final String currentUserPubkey; // The current user's pubkey

  const StarterPackSelectionBottomSheet({
    super.key,
    required this.userPubkey,
    required this.currentUserPubkey,
  });

  @override
  ConsumerState<StarterPackSelectionBottomSheet> createState() =>
      _StarterPackSelectionBottomSheetState();
}

class _StarterPackSelectionBottomSheetState
    extends ConsumerState<StarterPackSelectionBottomSheet> {
  final Set<String> _loadingPacks = <String>{};
  final Set<String> _successPacks = <String>{};

  @override
  Widget build(BuildContext context) {
    final followSetsList = ref.watch(
      nostrListsFollowStateProvider(widget.currentUserPubkey),
    );

    final userToAddMetadata = ref
        .watch(metadataStateProvider(widget.userPubkey))
        .userMetadata;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHandle(),
            const SizedBox(height: 16),
            Text(
              'Add ${userToAddMetadata?.name ?? ""} to Starter Pack',
              style: TextStyle(
                color: Theme.of(context).colorScheme.inverseSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            _buildContent(context, ref, followSetsList),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NostrListsFollowState followSetsList,
  ) {
    if (followSetsList.isLoading) {
      return const Padding(padding: EdgeInsets.all(40), child: SpinnerCenter());
    }

    if (followSetsList.publicNostrFollowSets.isEmpty) {
      return _buildEmptyState(context);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount:
            followSetsList.publicNostrFollowSets.length +
            1, // +1 for create new option
        itemBuilder: (context, index) {
          if (index == followSetsList.publicNostrFollowSets.length) {
            return _buildCreateNewOption(context);
          }

          final pack = followSetsList.publicNostrFollowSets[index];
          return _buildPackOption(context, ref, pack);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Icon(
          PhosphorIcons.listPlus(),
          size: 30,
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
        const SizedBox(height: 16),
        Text(
          'No starter packs found',
          style: TextStyle(
            color: Theme.of(context).colorScheme.inverseSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 40),
        _buildCreateNewOption(context),
      ],
    );
  }

  Widget _buildPackOption(BuildContext context, WidgetRef ref, NostrSet pack) {
    final isLoading = _loadingPacks.contains(pack.name);
    final isUserInPack = pack.elements.any(
      (element) => element.value == widget.userPubkey,
    );
    final wasJustAdded = _successPacks.contains(pack.name);
    final showCheck = isUserInPack || wasJustAdded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: showCheck || isLoading
              ? null
              : () => _addUserToPack(context, ref, pack),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.users(),
                  color: Theme.of(context).colorScheme.inverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title ?? pack.name,
                        style: TextStyle(
                          color: showCheck
                              ? Theme.of(context).colorScheme.inverseSurface
                              : Theme.of(context).colorScheme.inverseSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (pack.elements.isNotEmpty)
                        Text(
                          '${pack.elements.length} members',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.inverseSurface,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildTrailingIcon(isLoading, showCheck, wasJustAdded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingIcon(bool isLoading, bool showCheck, bool wasJustAdded) {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (showCheck) {
      return Icon(
        PhosphorIcons.check(),
        color: wasJustAdded
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.inverseSurface,
        size: 16,
      );
    }

    return Icon(
      PhosphorIcons.plus(),
      color: Theme.of(context).colorScheme.inverseSurface,
      size: 16,
    );
  }

  Widget _buildCreateNewOption(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _createNewPack(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.inverseSurface.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.plus(),
                  color: Theme.of(context).colorScheme.inverseSurface,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Create new starter pack',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inverseSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _addUserToPack(
    BuildContext context,
    WidgetRef ref,
    NostrSet pack,
  ) async {
    // Set loading state
    setState(() {
      _loadingPacks.add(pack.name);
    });

    try {
      final listsP = ref.read(nostrListProvider);
      await listsP.addUserToStarterPack(
        name: pack.name,
        pubkey: widget.userPubkey,
      );

      // Set success state
      setState(() {
        _loadingPacks.remove(pack.name);
        _successPacks.add(pack.name);
      });

      // Refresh data
      final myUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();
      Future.delayed(const Duration(milliseconds: 200)).then((_) {
        if (mounted) {
          ref.invalidate(nostrListProvider);
          ref.invalidate(nostrListsFollowStateProvider(myUserPubkey!));
        }
      });

      // Auto-close bottom sheet after success
      Future.delayed(const Duration(milliseconds: 1500)).then((_) {
        if (mounted) {
          context.pop();
        }
      });
    } catch (error) {
      // Handle error
      setState(() {
        _loadingPacks.remove(pack.name);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(PhosphorIcons.warning(), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Failed to add user to ${pack.title ?? pack.name}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _createNewPack(BuildContext context) {
    context.push(
      RoutePaths.starterPackEdit(
        pubkey: widget.currentUserPubkey,
        name: 'i-${Helpers().getRandomString(10)}',
        isNew: true,
      ),
    );
  }
}
