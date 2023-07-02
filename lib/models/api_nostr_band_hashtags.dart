class ApiNostrBandHashtags {
  final String type;
  final List<Hashtags> hashtags;
  final Map relays;

  ApiNostrBandHashtags({
    required this.type,
    required this.hashtags,
    required this.relays,
  });

  factory ApiNostrBandHashtags.fromJson(Map<String, dynamic> json) {
    List<dynamic> hashtagsJson = json['hashtags'] ?? [];
    List<Hashtags> hashtags = [];
    //cast using for loop
    for (Map<String, dynamic> hashtag in hashtagsJson) {
      var myHashtag = Hashtags.fromJson(hashtag);
      // filter out some hashtags
      // todo sentiment analysis
      if (myHashtag.hashtag.contains('nude')) continue;
      if (myHashtag.hashtag.contains('nsfw')) continue;
      hashtags.add(Hashtags.fromJson(hashtag));
    }

    return ApiNostrBandHashtags(
      type: json['type'],
      hashtags: hashtags,
      relays: json['relays'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['hashtags'] = hashtags.map((v) => v.toJson()).toList();
    data['relays'] = relays;
    return data;
  }
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

  factory Hashtags.fromJson(Map<String, dynamic> json) {
    List<dynamic> threadsJson = json['threads'] ?? [];
    List<Threads> threads = [];
    //cast using for loop
    for (Map<String, dynamic> thread in threadsJson) {
      threads.add(Threads.fromJson(thread));
    }

    return Hashtags(
      hashtag: json['hashtag'],
      threadsCount: json['threads_count'],
      threads: threads,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hashtag'] = hashtag;
    data['threads_count'] = threadsCount;
    data['threads'] = threads.map((v) => v.toJson()).toList();
    return data;
  }
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

  factory Threads.fromJson(Map<String, dynamic> json) {
    return Threads(
      id: json['id'] ?? '',
      kind: json['kind'] ?? -1,
      pubkey: json['pubkey'] ?? '',
      createdAt: json['created_at'] ?? -1,
      content: json['content'] ?? '',
      replies: json['replies'] ?? 0,
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      reposts: json['reposts'] ?? 0,
      zappers: json['zappers'] ?? 0,
      zapAmount: json['zap_amount'] ?? 0,
      replyToId: json['reply_to_id'] ?? '',
      rootId: json['root_id'] ?? '',
      lang: json['lang'] ?? '',
      relays: json['relays'].cast<int>() ?? [],
      author: json['author'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['kind'] = kind;
    data['pubkey'] = pubkey;
    data['created_at'] = createdAt;
    data['content'] = content;
    data['replies'] = replies;
    data['upvotes'] = upvotes;
    data['downvotes'] = downvotes;
    data['reposts'] = reposts;
    data['zappers'] = zappers;
    data['zap_amount'] = zapAmount;
    data['reply_to_id'] = replyToId;
    data['root_id'] = rootId;
    data['lang'] = lang;
    data['relays'] = relays;
    data['author'] = author;

    return data;
  }
}
