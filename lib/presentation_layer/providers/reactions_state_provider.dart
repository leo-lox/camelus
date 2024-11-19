import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/usecases/user_reactions.dart';
import 'reactions_provider.dart';

// Define the state class
class PostLikeState {
  final bool isLiked;
  final bool isLoading;

  PostLikeState({
    required this.isLiked,
    required this.isLoading,
  });

  PostLikeState copyWith({bool? isLiked, bool? isLoading}) {
    return PostLikeState(
      isLiked: isLiked ?? this.isLiked,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Create the StateNotifier
class PostLikeNotifier extends StateNotifier<PostLikeState> {
  final UserReactions _userReactions;
  final String _postId;
  final String _postAuthorPubkey;

  PostLikeNotifier(this._userReactions, this._postId, this._postAuthorPubkey)
      : super(PostLikeState(isLiked: false, isLoading: true)) {
    _initializeLikeState();
  }

  Future<void> _initializeLikeState() async {
    final isLiked = await _userReactions.isPostSelfLiked(postId: _postId);

    state = PostLikeState(isLiked: isLiked, isLoading: false);
  }

  Future<void> toggleLike() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      if (state.isLiked) {
        await _userReactions.deleteReaction(postId: _postId);
      } else {
        await _userReactions.likePost(
          pubkeyOfEventAuthor: _postAuthorPubkey,
          postId: _postId,
        );
      }

      state = state.copyWith(isLiked: !state.isLiked, isLoading: false);
    } catch (e) {
      // Handle error
      state = state.copyWith(isLoading: false);
    }
  }
}

// Create the provider family \
// first arg is the postId, second is the postAuthorPubkey
final postLikeProvider =
    StateNotifierProvider.family<PostLikeNotifier, PostLikeState, NostrNote>(
  (ref, arg) {
    final userReactions = ref.watch(reactionsProvider);
    return PostLikeNotifier(userReactions, arg.id, arg.pubkey);
  },
);
