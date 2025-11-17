import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/components/note_card/nostr_parser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../domain_layer/entities/nostr_note.dart';
import '../../../atoms/spinner_center.dart';
import '../../../components/note_card/note_card_container.dart';

import 'bookmarks_state_provider.dart';

class BookmarksPage extends ConsumerStatefulWidget {
  const BookmarksPage({super.key});

  @override
  ConsumerState<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends ConsumerState<BookmarksPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(String eventId, bool isPrivate, String notePreview) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeBookmark),
        content: Text('"$notePreview"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () {
              ref
                  .read(bookmarksStateProvider.notifier)
                  .removeBookmark(eventId, isPrivate);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.bookmarkRemoved),
                ),
              );
            },
            child: Text(
              AppLocalizations.of(context)!.removeBookmark,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(List<NostrNote> bookmarks, bool isPrivate) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIcons.bookmarkSimple(),
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              isPrivate
                  ? AppLocalizations.of(context)!.noPrivateBookmarks
                  : AppLocalizations.of(context)!.noPublicBookmarks,
              style: TextStyle(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final note = bookmarks[index];
        final notePreview = note.content.length > 50
            ? '${note.content.substring(0, 50)}...'
            : note.content;

        return Dismissible(
          key: Key(note.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: Icon(
              PhosphorIcons.trash(),
              color: Colors.white,
            ),
          ),
          confirmDismiss: (direction) async {
            _showDeleteDialog(note.id, isPrivate, notePreview);
            return false;
          },
          child: Column(
            children: [
              // Padding(
              //   padding:
              //       const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              //   child: Row(
              //     children: [
              //       Icon(
              //         PhosphorIcons.clock(),
              //         size: 14,
              //         color: Theme.of(context).colorScheme.outline,
              //       ),
              //       const SizedBox(width: 4),
              //       Text(
              //         'Bookmarked ${timeago.format(DateTime.fromMillisecondsSinceEpoch(note.createdAt * 1000))}',
              //         style: TextStyle(
              //           fontSize: 12,
              //           color: Theme.of(context).colorScheme.outline,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              const Divider(height: 1),
              FutureBuilder(
                  future: NostrParser.parseEvent(note),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SpinnerCenter();
                    } else if (snapshot.hasError) {
                      return ListTile(
                        title: Text('Error loading note'),
                        subtitle: Text(snapshot.error.toString()),
                      );
                    } else {
                      final parsedPost = snapshot.data!;
                      return NoteCardContainer(
                        note: parsedPost,
                      );
                    }
                  }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookmarksState = ref.watch(bookmarksStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.bookmarks),
        leading: BackButton(
          onPressed: () {
            // check if can pop otherwise go to home
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/home');
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.lock(), size: 16),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.privateBookmarks),
                  if (bookmarksState.privateBookmarks.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${bookmarksState.privateBookmarks.length}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIcons.globeHemisphereWest(), size: 16),
                  const SizedBox(width: 8),
                  Text(AppLocalizations.of(context)!.publicBookmarks),
                  if (bookmarksState.publicBookmarks.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${bookmarksState.publicBookmarks.length}',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: bookmarksState.isLoading
          ? Center(child: SpinnerCenter())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookmarksList(bookmarksState.privateBookmarks, true),
                _buildBookmarksList(bookmarksState.publicBookmarks, false),
              ],
            ),
    );
  }
}
