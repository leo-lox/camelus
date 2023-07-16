import 'package:camelus/models/socket_control.dart';

class Tweet {
  String id;
  String pubkey;
  String userFirstName;
  String userUserName;
  String userProfilePic;
  String content;
  List<String> imageLinks;
  int tweetedAt;
  int likesCount;
  int commentsCount;
  int retweetsCount;
  List<dynamic> tags;
  List<dynamic> replies;
  bool isReply = false;
  Map<String, Map<String, dynamic>> relayHints = {};

  Tweet(
      {required this.id,
      required this.pubkey,
      required this.userFirstName,
      required this.userUserName,
      required this.userProfilePic,
      required this.content,
      required this.imageLinks,
      required this.tweetedAt,
      required this.tags,
      required this.likesCount,
      required this.commentsCount,
      required this.retweetsCount,
      required this.replies,
      this.relayHints = const {},
      this.isReply = false});

  factory Tweet.fromJson(Map<String, dynamic> json) {
    return Tweet(
        id: json['id'],
        pubkey: json['pubkey'],
        userFirstName: json['userFirstName'],
        userUserName: json['userUserName'],
        userProfilePic: json['userProfilePic'],
        content: json['tweet'],
        imageLinks: json['imageLinks'].cast<String>(),
        tweetedAt: json['tweetedAt'],
        tags: json['tags'],
        replies: json['replies'],
        likesCount: json['likesCount'],
        commentsCount: json['commentsCount'],
        retweetsCount: json['retweetsCount'],
        isReply: json['isReply'],
        relayHints: {} //json['relayHints'] ?? {},
        );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pubkey': pubkey,
        'userFirstName': userFirstName,
        'userUserName': userUserName,
        'userProfilePic': userProfilePic,
        'tweet': content,
        'imageLinks': imageLinks,
        'tweetedAt': tweetedAt,
        'tags': tags,
        'replies': replies,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'retweetsCount': retweetsCount,
        'isReply': isReply,
        'relayHints': relayHints
      };

  factory Tweet.fromNostrEvent(dynamic eventMap, SocketControl socketControl) {
    int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // extract media links from content and remove from content
    String content = eventMap["content"];
    List<String> imageLinks = [];
    RegExp exp = RegExp(r"(https?:\/\/[^\s]+)");
    Iterable<RegExpMatch> matches = exp.allMatches(content);
    for (var match in matches) {
      var link = match.group(0);
      if (link!.endsWith(".jpg") ||
          link.endsWith(".jpeg") ||
          link.endsWith(".png") ||
          link.endsWith(".webp") ||
          link.endsWith(".gif")) {
        imageLinks.add(link);
        content = content.replaceAll(link, "");
      }
    }

    // check if it is a reply
    var isReply = false;
    for (var t in eventMap["tags"]) {
      if (t[0] == "e") {
        isReply = true;
      }
    }

    Map<String, Map<String, dynamic>> myRelayHints = {
      socketControl.connectionUrl: {
        "lastFetched": now,
      }
    };

    return Tweet(
        id: eventMap["id"],
        pubkey: eventMap["pubkey"],
        userFirstName: "name",
        userUserName: eventMap["pubkey"],
        userProfilePic: "",
        content: content,
        imageLinks: imageLinks,
        tweetedAt: eventMap["created_at"],
        tags: eventMap["tags"],
        replies: [],
        likesCount: 0,
        commentsCount: 0,
        retweetsCount: 0,
        relayHints: myRelayHints,
        isReply: isReply);
  }

  void updateRelayHintLastFetched(String relayUrl) {
    var now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (relayHints[relayUrl] == null) {
      relayHints[relayUrl] = {};
    }

    relayHints[relayUrl]!["lastFetched"] = now;
  }
}

List tweets = [
  Tweet(
    id: '1',
    pubkey: "pubkey",
    userFirstName: 'Lute',
    userUserName: 'Lute100',
    userProfilePic: 'assets/images/profile.webp',
    content: 'I still don\'t understand why... lorem ipsum',
    imageLinks: ['assets/images/content.png'],
    tweetedAt: 0,
    tags: [],
    replies: [],
    likesCount: 2,
    commentsCount: 3,
    retweetsCount: 5,
  ),
  Tweet(
      id: '2',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/profile.webp',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/CaptainJackSparrow.jpg'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '3',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/profile.webp',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: [],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '4',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '5',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '6',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '7',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '8',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '9',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
  Tweet(
      id: '10',
      pubkey: "pubkey",
      userFirstName: 'Lute',
      userUserName: 'Lute100',
      userProfilePic: 'assets/images/CaptainJackSparrow.jpg',
      content: 'I still don\'t understand why... lorem ipsum',
      imageLinks: ['assets/images/content.png'],
      tweetedAt: 0,
      tags: [],
      replies: [],
      likesCount: 2,
      commentsCount: 3,
      retweetsCount: 5),
];
