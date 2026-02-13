import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../domain_layer/entities/nostr_note.dart';
import '../../../providers/get_notes_provider.dart';
import '../../../providers/ndk_provider.dart';
import 'bookmarks_provider.dart';

class BookmarksState {
  final bool isLoading;
  final List<NostrNote> publicBookmarks;
  final List<NostrNote> privateBookmarks;
  final NostrList? bookmarksList;

  BookmarksState({
    required this.isLoading,
    required this.publicBookmarks,
    required this.privateBookmarks,
    this.bookmarksList,
  });

  BookmarksState copyWith({
    bool? isLoading,
    List<NostrNote>? publicBookmarks,
    List<NostrNote>? privateBookmarks,
    NostrList? bookmarksList,
  }) {
    return BookmarksState(
      isLoading: isLoading ?? this.isLoading,
      publicBookmarks: publicBookmarks ?? this.publicBookmarks,
      privateBookmarks: privateBookmarks ?? this.privateBookmarks,
      bookmarksList: bookmarksList ?? this.bookmarksList,
    );
  }
}

class BookmarksNotifier extends Notifier<BookmarksState> {
  StreamSubscription? _subscription;

  @override
  BookmarksState build() {
    ref.onDispose(() {
      _subscription?.cancel();
    });

    _loadBookmarks();

    return BookmarksState(
      isLoading: true,
      publicBookmarks: [],
      privateBookmarks: [],
    );
  }

  void _loadBookmarks() async {
    final ndk = ref.read(ndkProvider);
    final pubkey = ndk.accounts.getPublicKey();
    if (pubkey == null) return;

    final bookmarksUseCase = ref.read(bookmarksProvider);
    final getNotesUseCase = ref.read(getNotesProvider);

    // Get the bookmarks list
    final bookmarksList = await bookmarksUseCase.getSingleList(
      kind: NostrList.bookmarks,
    );

    if (bookmarksList == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    state = state.copyWith(bookmarksList: bookmarksList);

    // Get public bookmarks (thread events)
    final publicEventIds = bookmarksList.threads
        .where((e) => !e.private)
        .map((e) => e.value)
        .toList();

    // Get private bookmarks
    final privateEventIds = bookmarksList.threads
        .where((e) => e.private)
        .map((e) => e.value)
        .toList();

    List<NostrNote> publicNotes = [];
    List<NostrNote> privateNotes = [];

    // Load public bookmarked notes
    for (final eventId in publicEventIds) {
      await for (final note in getNotesUseCase.getNote(eventId)) {
        if (!publicNotes.any((n) => n.id == note.id)) {
          publicNotes.add(note);
        }
        break; // Get first result
      }
    }

    // Load private bookmarked notes
    for (final eventId in privateEventIds) {
      await for (final note in getNotesUseCase.getNote(eventId)) {
        if (!privateNotes.any((n) => n.id == note.id)) {
          privateNotes.add(note);
        }
        break; // Get first result
      }
    }

    // Sort by created date (newest first)
    publicNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    privateNotes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    state = state.copyWith(
      isLoading: false,
      publicBookmarks: publicNotes,
      privateBookmarks: privateNotes,
    );
  }

  Future<void> removeBookmark(String eventId, bool isPrivate) async {
    final bookmarksUseCase = ref.read(bookmarksProvider);

    // Remove from the list using the use case
    // NDK automatically handles both public and private elements
    await bookmarksUseCase.removeElementFromList(
      tag: 'e',
      value: eventId,
      kind: NostrList.bookmarks,
    );

    // Update local state
    if (isPrivate) {
      state = state.copyWith(
        privateBookmarks: state.privateBookmarks
            .where((n) => n.id != eventId)
            .toList(),
      );
    } else {
      state = state.copyWith(
        publicBookmarks: state.publicBookmarks
            .where((n) => n.id != eventId)
            .toList(),
      );
    }
  }
}

final bookmarksStateProvider =
    NotifierProvider<BookmarksNotifier, BookmarksState>(
      () => BookmarksNotifier(),
    );
