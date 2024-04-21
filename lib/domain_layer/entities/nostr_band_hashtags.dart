class NostrBandHashtags {
  final String type;
  final List<Hashtags> hashtags;
  final Map relays;

  NostrBandHashtags({
    required this.type,
    required this.hashtags,
    required this.relays,
  });
}

class Hashtags {
  final String hashtag;
  final int threadsCount;
  final List<Threads> threads;

  Hashtags({
    required this.hashtag,
    required this.threadsCount,
    required this.threads,
  });
}

class Threads {
  final String id;
  final int kind;
  final String pubkey;
  final int createdAt;
  final String content;
  final int replies;
  final int upvotes;
  final int downvotes;
  final int reposts;
  final int zappers;
  final int zapAmount;
  final String replyToId;
  final String rootId;
  final String lang;
  final List<int> relays;
  final Map author;

  Threads({
    required this.id,
    required this.kind,
    required this.pubkey,
    required this.createdAt,
    required this.content,
    required this.replies,
    required this.upvotes,
    required this.downvotes,
    required this.reposts,
    required this.zappers,
    required this.zapAmount,
    required this.replyToId,
    required this.rootId,
    required this.lang,
    required this.relays,
    required this.author,
  });
}
