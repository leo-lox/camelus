import 'package:riverpod/riverpod.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/usecases/user_reposts.dart';
import 'reposts_provider.dart';

/// class for to save state for each post if it is reposted or not
class PostRepostState {
  final bool isReposted;
  final bool isLoading;

  PostRepostState({
    required this.isReposted,
    required this.isLoading,
  });

  PostRepostState copyWith({bool? isReposted, bool? isLoading}) {
    return PostRepostState(
      isReposted: isReposted ?? this.isReposted,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final postRepostProvider = StateNotifierProvider.family<PostRepostNotifier,
    PostRepostState, NostrNote>(
  (ref, arg) {
    final userReactions = ref.watch(repostsProvider);
    return PostRepostNotifier(userReactions, arg);
  },
);

class PostRepostNotifier extends StateNotifier<PostRepostState> {
  final UserReposts _userReposts;
  final NostrNote _displayNote;

  PostRepostNotifier(
    this._userReposts,
    this._displayNote,
  ) : super(PostRepostState(isReposted: false, isLoading: true)) {
    _initializeRepostState();
  }

  Future<void> _initializeRepostState() async {
    final isReposted =
        await _userReposts.isPostSelfReposted(postId: _displayNote.id);

    state = state.copyWith(isReposted: isReposted, isLoading: false);
  }

  Future<void> toggleRepost() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      if (state.isReposted) {
        await _userReposts.deleteRepost(postId: _displayNote.id);
      } else {
        await _userReposts.repostPost(postToRepost: _displayNote);
      }
      state = state.copyWith(isReposted: !state.isReposted, isLoading: false);
    } catch (e) {
      print(e);
      // Handle error
      state = state.copyWith(isLoading: false);
    }
  }
}
