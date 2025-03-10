class NostrBandHashtags {
  final List<HashtagInfo> hashtags;

  NostrBandHashtags({required this.hashtags});
}

class HashtagInfo {
  final String hashtag;
  final int posts;

  HashtagInfo({required this.hashtag, required this.posts});
}
