import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/usecases/user_reactions.dart';
import 'reactions_provider.dart';

// Define the state class
class PostLikeState {
  final bool isLiked;
  final bool isLoading;

  PostLikeState({required this.isLiked, required this.isLoading});

  PostLikeState copyWith({bool? isLiked, bool? isLoading}) {
    return PostLikeState(
      isLiked: isLiked ?? this.isLiked,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Create the Notifier
class PostLikeNotifier extends Notifier<PostLikeState> {
  late final UserReactions _userReactions;
  late final String _postId;
  late final String _postAuthorPubkey;

  PostLikeNotifier(NostrNote note)
    : _postId = note.id,
      _postAuthorPubkey = note.pubkey;

  @override
  PostLikeState build() {
    final userReactions = ref.watch(reactionsProvider);
    _userReactions = userReactions;

    _initializeLikeState();

    return PostLikeState(isLiked: false, isLoading: true);
  }

  Future<void> _initializeLikeState() async {
    final isLiked = await _userReactions.isPostSelfLiked(postId: _postId);

    state = state.copyWith(isLiked: isLiked, isLoading: false);
  }

  Future<void> toggleLike() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);

    try {
      if (state.isLiked) {
        _userReactions.deleteReaction(postId: _postId);
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

// Create the provider family
// arg is the NostrNote
final postLikeProvider =
    NotifierProvider.family<PostLikeNotifier, PostLikeState, NostrNote>(
      PostLikeNotifier.new,
    );
