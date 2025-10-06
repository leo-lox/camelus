import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../providers/ndk_provider.dart';
import '../../routes/nostr/blockedUsers/block_page.dart';
import '../starter_packs/starter_pack_bottom_sheet_add.dart';

class BottomSheetOption {
  final Widget leading;
  final String label;
  final VoidCallback onTap;

  final Color? textColor;

  const BottomSheetOption({
    required this.leading,
    required this.label,
    required this.onTap,
    this.textColor,
  });
}

class MoreOptionsBottomSheet extends ConsumerWidget {
  final NostrNote note;

  const MoreOptionsBottomSheet({
    super.key,
    required this.note,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = _buildOptions(context, ref);

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
            const SizedBox(height: 20),
            ...options.map((option) => _buildOptionTile(option)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Builder(builder: (context) {
      return Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Paletter.getGray(context),
          borderRadius: BorderRadius.circular(2),
        ),
      );
    });
  }

  Widget _buildOptionTile(BottomSheetOption option) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: option.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                option.leading,
                const SizedBox(width: 16),
                Expanded(
                  child: Builder(builder: (context) {
                    return Text(
                      option.label,
                      style: TextStyle(
                        color:
                            option.textColor ?? Paletter.getLightGray(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BottomSheetOption> _buildOptions(BuildContext context, WidgetRef ref) {
    return [
      BottomSheetOption(
        leading: Icon(
          PhosphorIcons.userCirclePlus(),
          color: Paletter.getGray(context),
        ),
        label: AppLocalizations.of(context)!.addToStarterPack,
        onTap: () => _showFollowPackSelection(context, ref),
      ),
      BottomSheetOption(
        leading: Icon(
          PhosphorIcons.speakerSimpleSlash(),
          color: Paletter.getGray(context),
        ),
        label: AppLocalizations.of(context)!.blockReport,
        onTap: () => _navigateToBlockPage(context),
      ),
    ];
  }

  void _showFollowPackSelection(BuildContext context, WidgetRef ref) {
    context.pop();
    // Close current bottom sheet

    // You'll need to get the current user's pubkey - adjust this based on your app structure
    final currentUserPubkey = ref.read(ndkProvider).accounts.getPublicKey();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => StarterPackSelectionBottomSheet(
        userPubkey: note.pubkey,
        currentUserPubkey: currentUserPubkey!,
      ),
    );
  }

  void _navigateToBlockPage(BuildContext context) {
    context.pop();
    ; // Close bottom sheet first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockPage(
          postId: note.id,
          userPubkey: note.pubkey,
        ),
      ),
    );
  }
}

// Updated function to use the new component
void openBottomSheetMore(BuildContext context, NostrNote note) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    enableDrag: true,
    builder: (context) => MoreOptionsBottomSheet(note: note),
  );
}
