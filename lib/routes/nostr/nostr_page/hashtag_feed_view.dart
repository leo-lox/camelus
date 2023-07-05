import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HashtagFeedView extends ConsumerStatefulWidget {
  final String hashtag;

  const HashtagFeedView({Key? key, required this.hashtag}) : super(key: key);

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
    return Center(
      child: Text("HashtagFeedView ${widget.hashtag}"),
    );
  }
}
