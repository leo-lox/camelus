import 'package:camelus/domain_layer/entities/nostr_band_hashtags.dart';

class NostrBandHashtagsModel extends NostrBandHashtags {
  NostrBandHashtagsModel({
    required super.type,
    required super.hashtags,
    required super.relays,
  });

  factory NostrBandHashtagsModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> hashtagsJson = json['hashtags'] ?? [];
    List<HashtagsModel> hashtags = [];
    //cast using for loop
    for (Map<String, dynamic> hashtag in hashtagsJson) {
      var myHashtag = HashtagsModel.fromJson(hashtag);
      // filter out some hashtags
      // todo sentiment analysis
      if (myHashtag.hashtag.contains('nude')) continue;
      if (myHashtag.hashtag.contains('nsfw')) continue;
      hashtags.add(HashtagsModel.fromJson(hashtag));
    }

    return NostrBandHashtagsModel(
      type: json['type'],
      hashtags: hashtags,
      relays: json['relays'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['hashtags'] = hashtags
        .map((v) => {
              HashtagsModel(
                hashtag: v.hashtag,
                threads: v.threads,
                threadsCount: v.threadsCount,
              ).toJson()
            })
        .toList();

    data['relays'] = relays;
    return data;
  }
}

class HashtagsModel extends Hashtags {
  HashtagsModel({
    required super.hashtag,
    required super.threadsCount,
    required super.threads,
  });

  static Map<String, dynamic> toJsonFromInstance(HashtagsModel instance) {
    return instance.toJson();
  }

  factory HashtagsModel.fromJson(Map<String, dynamic> json) {
    List<dynamic> threadsJson = json['threads'] ?? [];
    List<Threads> threads = [];
    //cast using for loop
    for (Map<String, dynamic> thread in threadsJson) {
      threads.add(ThreadsModel.fromJson(thread));
    }

    return HashtagsModel(
      hashtag: json['hashtag'],
      threadsCount: json['threads_count'],
      threads: threads,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['hashtag'] = hashtag;
    data['threads_count'] = threadsCount;
    //data['threads'] = threads.map((v) => v.toJson()).toList();
    data['threads'] = threads
        .map((v) => {
              ThreadsModel(
                author: v.author,
                content: v.content,
                createdAt: v.createdAt,
                downvotes: v.downvotes,
                id: v.id,
                kind: v.kind,
                lang: v.lang,
                pubkey: v.pubkey,
                relays: v.relays,
                replyToId: v.replyToId,
                reposts: v.reposts,
                rootId: v.rootId,
                upvotes: v.upvotes,
                zappers: v.zappers,
                zapAmount: v.zapAmount,
                replies: v.replies,
              ).toJson()
            })
        .toList();
    return data;
  }
}

class ThreadsModel extends Threads {
  ThreadsModel({
    required super.id,
    required super.kind,
    required super.pubkey,
    required super.createdAt,
    required super.content,
    required super.replies,
    required super.upvotes,
    required super.downvotes,
    required super.reposts,
    required super.zappers,
    required super.zapAmount,
    required super.replyToId,
    required super.rootId,
    required super.lang,
    required super.relays,
    required super.author,
  });

  factory ThreadsModel.fromJson(Map<String, dynamic> json) {
    return ThreadsModel(
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
