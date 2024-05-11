import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HashtagFeedView extends ConsumerStatefulWidget {
  final String hashtag;

  const HashtagFeedView({super.key, required this.hashtag});

  @override
  ConsumerState<HashtagFeedView> createState() => _HashtagFeedViewState();
}

class _HashtagFeedViewState extends ConsumerState<HashtagFeedView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text("HashtagFeedView not implemented");
  }
}
