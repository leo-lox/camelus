import 'dart:ui';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_list.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../providers/ndk_provider.dart';
import '../../routes/nostr/blockedUsers/block_page.dart';
import '../../routes/nostr/bookmarks/bookmarks_provider.dart';
import '../../routes/nostr/bookmarks/bookmarks_state_provider.dart';
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

class MoreOptionsBottomSheet extends ConsumerStatefulWidget {
  final NostrNote note;

  const MoreOptionsBottomSheet({
    super.key,
    required this.note,
  });

  @override
  ConsumerState<MoreOptionsBottomSheet> createState() =>
      _MoreOptionsBottomSheetState();
}

class _MoreOptionsBottomSheetState
    extends ConsumerState<MoreOptionsBottomSheet> {
  bool _isAddingBookmark = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
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
            ...options,
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

  Widget _buildBookmarkOption(BuildContext context) {
    final bookmarksState = ref.watch(bookmarksStateProvider);

    // Check if note is already bookmarked (in either public or private)
    final isBookmarked =
        bookmarksState.publicBookmarks.any((n) => n.id == widget.note.id) ||
            bookmarksState.privateBookmarks.any((n) => n.id == widget.note.id);
    final isPrivateBookmark =
        bookmarksState.privateBookmarks.any((n) => n.id == widget.note.id);

    if (_isAddingBookmark) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Paletter.getGray(context),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isBookmarked
                      ? 'Removing from bookmarks...'
                      : 'Adding to bookmarks...',
                  style: TextStyle(
                    color: Paletter.getLightGray(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.warningCircle(),
                color: Theme.of(context).colorScheme.error,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isBookmarked) {
      return _buildOptionTile(
        BottomSheetOption(
          leading: Icon(
            PhosphorIcons.bookmarkSimple(PhosphorIconsStyle.fill),
            color: Theme.of(context).colorScheme.primary,
          ),
          label: 'Remove from bookmarks',
          onTap: () => _removeFromBookmarks(context, ref, isPrivateBookmark),
          textColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }

    return _buildOptionTile(
      BottomSheetOption(
        leading: Icon(
          PhosphorIcons.bookmarkSimple(),
          color: Paletter.getGray(context),
        ),
        label: 'Add to bookmarks',
        onTap: () => _addToBookmarks(context, ref),
      ),
    );
  }

  List<Widget> _buildOptions(BuildContext context, WidgetRef ref) {
    return [
      _buildOptionTile(
        BottomSheetOption(
          leading: Icon(
            PhosphorIcons.userCirclePlus(),
            color: Paletter.getGray(context),
          ),
          label: AppLocalizations.of(context)!.addToStarterPack,
          onTap: () => _showFollowPackSelection(context, ref),
        ),
      ),
      _buildBookmarkOption(context),
      _buildOptionTile(
        BottomSheetOption(
          leading: Icon(
            PhosphorIcons.speakerSimpleSlash(),
            color: Paletter.getGray(context),
          ),
          label: AppLocalizations.of(context)!.blockReport,
          onTap: () => _navigateToBlockPage(context),
        ),
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
        userPubkey: widget.note.pubkey,
        currentUserPubkey: currentUserPubkey!,
      ),
    );
  }

  void _navigateToBlockPage(BuildContext context) {
    context.pop(); // Close bottom sheet first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlockPage(
          postId: widget.note.id,
          userPubkey: widget.note.pubkey,
        ),
      ),
    );
  }

  Future<void> _addToBookmarks(BuildContext context, WidgetRef ref) async {
    setState(() {
      _isAddingBookmark = true;
      _errorMessage = null;
    });

    try {
      final bookmarksUseCase = ref.read(bookmarksProvider);

      // Add to private bookmarks by default
      await bookmarksUseCase.addElementToList(
        tag: 'e',
        value: widget.note.id,
        kind: NostrList.bookmarks,
        private: true,
      );

      if (mounted) {
        // Refresh bookmarks state
        ref.invalidate(bookmarksStateProvider);
        setState(() {
          _isAddingBookmark = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingBookmark = false;
          _errorMessage = 'Failed to add bookmark';
        });

        // Clear error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    }
  }

  Future<void> _removeFromBookmarks(
      BuildContext context, WidgetRef ref, bool isPrivate) async {
    setState(() {
      _isAddingBookmark = true;
      _errorMessage = null;
    });

    try {
      final bookmarksUseCase = ref.read(bookmarksProvider);

      // Remove from bookmarks
      await bookmarksUseCase.removeElementFromList(
        tag: 'e',
        value: widget.note.id,
        kind: NostrList.bookmarks,
      );

      if (mounted) {
        // Refresh bookmarks state
        ref.invalidate(bookmarksStateProvider);
        setState(() {
          _isAddingBookmark = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAddingBookmark = false;
          _errorMessage = 'Failed to remove bookmark';
        });

        // Clear error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    }
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
