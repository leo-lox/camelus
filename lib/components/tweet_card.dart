import 'dart:developer';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/post_context.dart';
import 'package:camelus/models/tweet.dart';
import 'package:camelus/models/tweet_control.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:timeago_flutter/timeago_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher_string.dart';

import '../services/nostr/nostr_service.dart';

class TweetCard extends StatefulWidget {
  final Tweet tweet;
  final TweetControl? tweetControl;
  late NostrService _nostrService;
  TweetCard({Key? key, required this.tweet, this.tweetControl})
      : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<TweetCard> {
  late ImageProvider myImage;

  List<TextSpan> textSpans = [];

  final Map<String, dynamic> _tagsMetadata = {};

  List<TextSpan> _buildTextSpans(String content) {
    var spans = _buildUrlSpans(content);
    var completeSpans = _buildHashtagSpans(spans);

    return completeSpans;
  }

  List<TextSpan> _buildUrlSpans(String input) {
    final spans = <TextSpan>[];
    final linkRegex = RegExp(
        r"(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]");
    final linkMatches = linkRegex.allMatches(input);
    int lastMatchEnd = 0;
    for (final match in linkMatches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: input.substring(lastMatchEnd, match.start),
            style: const TextStyle(
                color: Palette.lightGray, fontSize: 17, height: 1.3),
          ),
        );
      }
      spans.add(TextSpan(
          text: match.group(0),
          style: const TextStyle(
              color: Palette.primary,
              fontSize: 17,
              height: 1.3,
              decoration: TextDecoration.underline),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (match.group(0) == null) return;

              // Open the URL in a browser
              launchUrlString(match.group(0)!,
                  mode: LaunchMode.externalApplication);
              log(match.group(0)!);
            }));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < input.length) {
      spans.add(TextSpan(
          text: input.substring(lastMatchEnd),
          style: const TextStyle(
              color: Palette.lightGray, fontSize: 17, height: 1.3)));
    }
    return spans;
  }

  List<TextSpan> _buildHashtagSpans(List<TextSpan> spans) {
    var finalSpans = <TextSpan>[];

    for (var span in spans) {
      if (span.text!.contains("#[")) {
        final pattern = RegExp(r"#\[\d+\]");
        final hashMatches = pattern.allMatches(span.text!);
        int lastMatchEnd = 0;
        for (final match in hashMatches) {
          if (match.start > lastMatchEnd) {
            finalSpans.add(
              TextSpan(
                text: span.text!.substring(lastMatchEnd, match.start),
                style: const TextStyle(
                    color: Palette.lightGray, fontSize: 17, height: 1.3),
              ),
            );
          }
          var indexString =
              match.group(0)!.replaceAll("#[", "").replaceAll("]", "");
          var index = int.parse(indexString);
          var tag = widget.tweet.tags[index];

          if (tag[0] == 'p' && _tagsMetadata[tag[1]] == null) {
            var pubkeyBech = Helpers().encodeBech32(tag[1], "npub");
            // first 5 chars then ... then last 5 chars
            var pubkeyHr =
                "${pubkeyBech.substring(0, 5)}...${pubkeyBech.substring(pubkeyBech.length - 5)}";
            _tagsMetadata[tag[1]] = pubkeyHr;
            var metadata = widget._nostrService.getUserMetadata(tag[1]);

            metadata.then((value) {
              setState(() {
                _tagsMetadata[tag[1]] = value["name"] ?? pubkeyHr;
              });
            });
          }
          finalSpans.add(TextSpan(
              text: "@${_tagsMetadata[tag[1]]}",
              style: const TextStyle(
                  color: Palette.primary, fontSize: 17, height: 1.3),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  Navigator.pushNamed(context, "/nostr/profile",
                      arguments: tag[1]);
                }));
          lastMatchEnd = match.end;
        }
        if (lastMatchEnd < span.text!.length) {
          finalSpans.add(
            TextSpan(
              text: span.text!.substring(lastMatchEnd),
              style: const TextStyle(
                  color: Palette.lightGray, fontSize: 17, height: 1.3),
            ),
          );
        }
      } else {
        finalSpans.add(span);
      }
    }

    return finalSpans;
  }

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
    Navigator.pushNamed(context, "/nostr/event", arguments: widget.tweet.id);
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tweet.imageLinks.isNotEmpty) {
      myImage = Image.network(widget.tweet.imageLinks[0], fit: BoxFit.fill,
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

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _openReplies(context);
      },
      child: Stack(
        children: [
          if ((widget.tweetControl?.showVerticalLineTop) ?? false)
            Positioned(
              top: 0,
              left: 49,
              child: Container(
                height: 50,
                width: 2,
                color: Palette.gray,
              ),
            ),
          if ((widget.tweetControl?.showVerticalLineBottom) ?? false)
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
              Container(
                // fix so whole card is clickable
                //color: Palette.purple,
                margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                // debug:  color if is reply
                //color: tweet.isReply ? Palette.darkGray : null,
                // height: 200.0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.tweet.isReply &&
                          (widget.tweetControl?.showInReplyTo ?? true))
                        Container(
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 15),
                          child: Row(
                            children: [
                              const SizedBox(width: 25),
                              const Text("in reply to ",
                                  style: TextStyle(
                                      fontSize: 16, color: Palette.gray)),
                              const SizedBox(width: 5),
                              if (Helpers()
                                  .getPubkeysFromTags(widget.tweet.tags)
                                  .isNotEmpty) //todo this is a hotfix to not break the feed
                                FutureBuilder(
                                  future: widget._nostrService.getUserMetadata(
                                      Helpers().getPubkeysFromTags(
                                              widget.tweet.tags)[
                                          0]), // todo fix this for multiple tags
                                  builder: (BuildContext context,
                                      AsyncSnapshot<Map> snapshot) {
                                    var name = "";
                                    if (snapshot.hasData) {
                                      name = snapshot.data?["name"] ?? "";
                                      // only calculate when necessary
                                      if (name.isEmpty) {
                                        var pubkey = Helpers()
                                            .getPubkeysFromTags(
                                                widget.tweet.tags)[0];
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
                                                        widget.tweet.tags)[
                                                0]); // todo fix this for multiple tags
                                      },
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            color: Palette.lightGray,
                                            decoration:
                                                TextDecoration.underline),
                                      ),
                                    );
                                  },
                                ),
                              if (Helpers()
                                      .getEventsFromTags(widget.tweet.tags)
                                      .length >
                                  1)
                                Text(
                                  " and ${Helpers().getEventsFromTags(widget.tweet.tags).length - 1} more",
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
                                  arguments: widget.tweet.pubkey);
                            },
                            child: FutureBuilder<Map>(
                                future: widget._nostrService
                                    .getUserMetadata(widget.tweet.pubkey),
                                builder: (BuildContext context,
                                    AsyncSnapshot<Map> snapshot) {
                                  var picture = "";

                                  if (snapshot.hasData) {
                                    picture = snapshot.data?["picture"] ??
                                        "https://avatars.dicebear.com/api/personas/${widget.tweet.pubkey}.svg";
                                  } else if (snapshot.hasError) {
                                    picture =
                                        "https://avatars.dicebear.com/api/personas/${widget.tweet.pubkey}.svg";
                                  } else {
                                    // loading
                                    picture =
                                        "https://avatars.dicebear.com/api/personas/${widget.tweet.pubkey}.svg";
                                  }

                                  return myProfilePicture(
                                      picture, widget.tweet.pubkey);
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
                                            future: widget._nostrService
                                                .getUserMetadata(
                                                    widget.tweet.pubkey),
                                            builder: (BuildContext context,
                                                AsyncSnapshot<Map> snapshot) {
                                              var name = "";

                                              if (snapshot.hasData) {
                                                var npubHr = Helpers()
                                                    .encodeBech32(
                                                        widget.tweet.pubkey,
                                                        "npub");
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
                                                    widget.tweet.tweetedAt *
                                                        1000)),
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
                                  // content
                                  RichText(
                                    text: TextSpan(
                                      children: _buildTextSpans(
                                        widget.tweet.content,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),
                                  if (widget.tweet.imageLinks.isNotEmpty &&
                                      widget.tweet.imageLinks != null)
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
                                          onTap: () => {
                                            _writeReply(context, widget.tweet)
                                          },
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
                                                widget.tweet.commentsCount > 0
                                                    ? widget.tweet.commentsCount
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
                                              widget.tweet.retweetsCount
                                                  .toString(),
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
                                                widget.tweet.likesCount
                                                    .toString(),
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
              const Divider(
                thickness: 0.3,
                color: Palette.darkGray,
              )
            ],
          ),
        ],
      ),
    );
  }
}
