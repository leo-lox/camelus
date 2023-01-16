import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/PostContext.dart';
import 'package:camelus/models/Tweet.dart';
import 'package:camelus/models/TweetControl.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../services/nostr/nostr_service.dart';

class TweetCard extends StatelessWidget {
  final Tweet tweet;
  final TweetControl? tweetControl;
  late NostrService _nostrService;
  TweetCard({Key? key, required this.tweet, this.tweetControl})
      : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  late ImageProvider myImage;

  // open image in full screen with dialog and zoom
  void openImage(ImageProvider image, BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            clipBehavior: Clip.antiAliasWithSaveLayer,
            insetPadding: const EdgeInsets.all(5),
            child: InteractiveViewer(
              child: Image(image: image),
            ),
          );
        });
  }

  void _openReplies(context) {
    //if (tweet.replies.isEmpty) {
    //  return;
    //}
    Navigator.pushNamed(context, "/nostr/event", arguments: tweet.id);
  }

  void _writeReply(ctx, Tweet tweet) {
    showModalBottomSheet(
        isScrollControlled: true,
        elevation: 10,
        backgroundColor: Palette.background,
        isDismissible: false,
        context: ctx,
        builder: (ctx) => BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom),
                  child: WritePost(
                    context: PostContext(replyToTweet: tweet),
                  )),
            ));
  }

  @override
  Widget build(BuildContext context) {
    if (tweet.imageLinks.isNotEmpty) {
      myImage = Image.network(tweet.imageLinks[0], fit: BoxFit.fill,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
          ),
        );
      }).image;
    }

    return Stack(
      children: [
        if ((tweetControl?.showVerticalLineTop) ?? false)
          Positioned(
            top: 0,
            left: 49,
            child: Container(
              height: 50,
              width: 2,
              color: Palette.gray,
            ),
          ),
        if ((tweetControl?.showVerticalLineBottom) ?? false)
          //line from profile picture to bottom of tweet
          Positioned(
            top: 50,
            bottom: 0,
            left: 49,
            child: Container(
              height: 50,
              width: 2,
              color: Palette.gray,
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                _openReplies(context);
              },
              child: Container(
                // fix so whole card is clickable
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                // debug:  color if is reply
                //color: tweet.isReply ? Palette.darkGray : null,
                // height: 200.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tweet.isReply &&
                          (tweetControl?.showInReplyTo ?? true))
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                          child: Row(
                            children: [
                              const SizedBox(width: 25),
                              const Text("in reply to ",
                                  style: TextStyle(
                                      fontSize: 16, color: Palette.gray)),
                              const SizedBox(width: 5),
                              FutureBuilder(
                                future: _nostrService.getUserMetadata(
                                    Helpers().getPubkeysFromTags(tweet.tags)[
                                        0]), // todo fix this for multiple tags
                                builder: (BuildContext context,
                                    AsyncSnapshot<Map> snapshot) {
                                  var name = "";
                                  if (snapshot.hasData) {
                                    name = snapshot.data?["name"] ?? "";
                                    // only calculate when necessary
                                    if (name.isEmpty) {
                                      var pubkey = Helpers()
                                          .getPubkeysFromTags(tweet.tags)[0];
                                      var pubkeyHr = Helpers()
                                          .encodeBech32(pubkey, "npub");
                                      var pubkeyHrShort = pubkeyHr.substring(
                                              0, 5) +
                                          "..." +
                                          pubkeyHr
                                              .substring(pubkeyHr.length - 5);
                                      name = pubkeyHrShort;
                                    }
                                  } else if (snapshot.hasError) {
                                    name = "error";
                                  } else {
                                    // loading
                                    name = "...";
                                  }
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.popAndPushNamed(
                                          context, "/nostr/event",
                                          arguments: Helpers()
                                                  .getEventsFromTags(
                                                      tweet.tags)[
                                              0]); // todo fix this for multiple tags
                                    },
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          color: Palette.lightGray,
                                          decoration: TextDecoration.underline),
                                    ),
                                  );
                                },
                              ),
                              if (Helpers()
                                      .getEventsFromTags(tweet.tags)
                                      .length >
                                  1)
                                Text(
                                  " and ${Helpers().getEventsFromTags(tweet.tags).length - 1} more",
                                  style: const TextStyle(
                                      fontSize: 16, color: Palette.gray),
                                )
                            ],
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, "/nostr/profile",
                                  arguments: tweet.pubkey);
                            },
                            child: FutureBuilder<Map>(
                                future:
                                    _nostrService.getUserMetadata(tweet.pubkey),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Map> snapshot) {
                                  var picture = "";

                                  if (snapshot.hasData) {
                                    picture = snapshot.data?["picture"] ??
                                        "https://avatars.dicebear.com/api/personas/${tweet.pubkey}.svg";
                                  } else if (snapshot.hasError) {
                                    picture =
                                        "https://avatars.dicebear.com/api/personas/${tweet.pubkey}.svg";
                                  } else {
                                    // loading
                                    picture =
                                        "https://avatars.dicebear.com/api/personas/${tweet.pubkey}.svg";
                                  }

                                  return myProfilePicture(
                                      picture, tweet.pubkey);
                                }),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      //mainAxisAlignment: MainAxisAlignment.end,
                                      //crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        FutureBuilder<Map>(
                                            future: _nostrService
                                                .getUserMetadata(tweet.pubkey),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Map> snapshot) {
                                              var name = "";

                                              if (snapshot.hasData) {
                                                var npubHr = Helpers()
                                                    .encodeBech32(
                                                        tweet.pubkey, "npub");
                                                var npubHrShort =
                                                    "${npubHr.substring(0, 4)}...${npubHr.substring(npubHr.length - 4)}";
                                                name = snapshot.data?["name"] ??
                                                    npubHrShort;
                                              } else if (snapshot.hasError) {
                                                name = "error";
                                              } else {
                                                // loading
                                                name = "loading";
                                              }

                                              return Container(
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 50,
                                                        maxWidth: 150),
                                                child: RichText(
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  text: TextSpan(
                                                    text: name,
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 17),
                                                  ),
                                                ),
                                              );
                                            }),
                                        const SizedBox(width: 10),
                                        Container(
                                          height: 3,
                                          width: 3,
                                          decoration: const BoxDecoration(
                                            color: Palette.gray,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            timeago.format(DateTime
                                                .fromMillisecondsSinceEpoch(
                                                    tweet.tweetedAt * 1000)),
                                            style: const TextStyle(
                                                color: Palette.gray,
                                                fontSize: 12),
                                          ),
                                        ),
                                        SvgPicture.asset(
                                          'assets/icons/tweetSetting.svg',
                                          color: Palette.darkGray,
                                        ),
                                      ]),
                                  const SizedBox(height: 2),
                                  Text(tweet.content,
                                      style: const TextStyle(
                                          color: Palette.lightGray,
                                          fontSize: 17,
                                          height: 1.3)),
                                  const SizedBox(height: 6),
                                  if (tweet.imageLinks.isNotEmpty &&
                                      tweet.imageLinks != null)
                                    GestureDetector(
                                      onTap: () => openImage(myImage, context),
                                      child: Container(
                                        height: 200,
                                        decoration: BoxDecoration(
                                          color: Palette.darkGray,
                                          shape: BoxShape.rectangle,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: myImage),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              {_writeReply(context, tweet)},
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                height: 23,
                                                'assets/icons/chat-teardrop-text.svg',
                                                color: Palette.darkGray,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                // show number of comments if >0
                                                tweet.commentsCount > 0
                                                    ? tweet.commentsCount
                                                        .toString()
                                                    : "",

                                                style: const TextStyle(
                                                    color: Palette.gray,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            SvgPicture.asset(
                                              'assets/icons/retweet.svg',
                                              color: Palette.darkGray,
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              tweet.retweetsCount.toString(),
                                              style: const TextStyle(
                                                  color: Palette.gray,
                                                  fontSize: 16),
                                            ),
                                          ],
                                        ),
                                        // like button
                                        GestureDetector(
                                          onTap: () => {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Like functionality is not implemented yet'),
                                              duration: Duration(seconds: 1),
                                            )),
                                          },
                                          child: Row(
                                            children: [
                                              SvgPicture.asset(
                                                height: 23,
                                                'assets/icons/heart.svg',
                                                color: Palette.darkGray,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                tweet.likesCount.toString(),
                                                style: const TextStyle(
                                                    color: Palette.gray,
                                                    fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(const SnackBar(
                                              content: Text(
                                                  'Share functionality is not implemented yet'),
                                              duration: Duration(seconds: 1),
                                            )),
                                          },
                                          child: SvgPicture.asset(
                                            height: 23,
                                            'assets/icons/share.svg',
                                            color: Palette.darkGray,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // show text if replies > 0
                                  if (tweet.isReply)
                                    Text(
                                      "debug: isReply ${tweet.replies.length}",
                                      style: TextStyle(
                                          color: Palette.darkGray, fontSize: 7),
                                    ),
                                  if (false)
                                    GestureDetector(
                                      onTap: (() {
                                        _openReplies(context);
                                      }),
                                      child: const Text(
                                        'Show this thread',
                                        style:
                                            TextStyle(color: Palette.primary),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(
              thickness: 0.3,
              color: Palette.darkGray,
            )
          ],
        ),
      ],
    );
  }
}
