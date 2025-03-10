import '../../domain_layer/entities/nostr_band_hashtags.dart';

class NostrBandHashtagsModel extends NostrBandHashtags {
  NostrBandHashtagsModel({
    required super.hashtags,
  });

  Map<String, dynamic> toJson() {
    return {
      'hashtags': hashtags
          .map((hashtag) => HashtagInfoModel(
                hashtag: hashtag.hashtag,
                posts: hashtag.posts,
              ).toJson())
          .toList(),
    };
  }

  factory NostrBandHashtagsModel.fromJson(Map<String, dynamic> json) {
    return NostrBandHashtagsModel(
      hashtags: (json['hashtags'] as List)
          .map((hashtagJson) => HashtagInfoModel.fromJson(hashtagJson))
          .toList(),
    );
  }
}

class HashtagInfoModel extends HashtagInfo {
  HashtagInfoModel({
    required super.hashtag,
    required super.posts,
  });

  Map<String, dynamic> toJson() {
    return {
      'hashtag': hashtag,
      'posts': posts,
    };
  }

  factory HashtagInfoModel.fromJson(Map<String, dynamic> json) {
    return HashtagInfoModel(
      hashtag: json['hashtag'] as String,
      posts: json['posts'] as int,
    );
  }
}
