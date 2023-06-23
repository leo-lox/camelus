import 'dart:developer';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/bottom_sheet_share.dart';
import 'package:camelus/components/images_tile_view.dart';
import 'package:camelus/components/note_card/bottom_sheet_more.dart';
import 'package:camelus/components/note_card/note_card_build_split_content.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:timeago/timeago.dart' as timeago;

class NoteCard extends ConsumerStatefulWidget {
  final NostrNote note;

  const NoteCard({Key? key, required this.note}) : super(key: key);

  @override
  ConsumerState<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends ConsumerState<NoteCard> {
  String nip05verified = "";

  void _checkNip05(
      String nip05, String pubkey, NostrService nostrService) async {
    if (nip05.isEmpty) return;
    if (nip05verified.isNotEmpty) return;
    try {
      var check = await nostrService.checkNip05(nip05, pubkey);

      if (check["valid"] == true) {
        setState(() {
          nip05verified = check["nip05"];
        });
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  _openProfile(String pubkey) {
    Navigator.pushNamed(context, "/nostr/profile", arguments: pubkey);
  }

  void _splitContentStateUpdate() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final myNostrService = ref.watch(nostrServiceProvider);

    final myMetadata = myNostrService.getUserMetadata(widget.note.pubkey);

    final splitContent = NoteCardSplitContent(
        widget.note, myNostrService, _openProfile, _splitContentStateUpdate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          // fix so whole card is clickable
          //color: Palette.purple,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          // debug:  color if is reply
          //color: tweet.isReply ? Palette.darkGray : null,
          // height: 200.0,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, "/nostr/profile",
                            arguments: widget.note.pubkey);
                      },
                      child: FutureBuilder<Map>(
                          future: myMetadata,
                          builder: (BuildContext context,
                              AsyncSnapshot<Map> snapshot) {
                            var picture = "";
                            var defaultPicture =
                                "https://avatars.dicebear.com/api/personas/${widget.note.pubkey}.svg";
                            if (snapshot.hasData) {
                              picture =
                                  snapshot.data?["picture"] ?? defaultPicture;
                            } else if (snapshot.hasError) {
                              picture = defaultPicture;
                            } else {
                              // loading
                              picture = defaultPicture;
                            }

                            return myProfilePicture(
                              pictureUrl: picture,
                              pubkey: widget.note.pubkey,
                              filterQuality: FilterQuality.medium,
                            );
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
                                      future: myMetadata,
                                      builder: (BuildContext context,
                                          AsyncSnapshot<Map> snapshot) {
                                        var name = "";

                                        if (snapshot.hasData) {
                                          var npubHr = Helpers().encodeBech32(
                                              widget.note.pubkey, "npub");
                                          var npubHrShort =
                                              "${npubHr.substring(0, 4)}...${npubHr.substring(npubHr.length - 4)}";
                                          name = snapshot.data?["name"] ??
                                              npubHrShort;
                                          _checkNip05(
                                              snapshot.data?["nip05"] ?? "",
                                              widget.note.pubkey,
                                              myNostrService);
                                        } else if (snapshot.hasError) {
                                          name = "error";
                                        } else {
                                          // loading
                                          name = "loading";
                                        }

                                        return Row(
                                          children: [
                                            Container(
                                              constraints: const BoxConstraints(
                                                  minWidth: 5, maxWidth: 150),
                                              child: RichText(
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                text: TextSpan(
                                                  text: name,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 17),
                                                ),
                                              ),
                                            ),
                                            if (nip05verified.isNotEmpty)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 0, left: 5),
                                                child: const Icon(
                                                  Icons.verified,
                                                  color: Palette.white,
                                                  size: 15,
                                                ),
                                              ),
                                          ],
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
                                      timeago.format(
                                          DateTime.fromMillisecondsSinceEpoch(
                                              widget.note.created_at * 1000)),
                                      style: const TextStyle(
                                          color: Palette.gray, fontSize: 12),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      openBottomSheetMore(context, widget.note);
                                    },
                                    child: SvgPicture.asset(
                                      'assets/icons/tweetSetting.svg',
                                      color: Palette.darkGray,
                                    ),
                                  )
                                ]),
                            const SizedBox(height: 2),

                            // content
                            splitContent.content,

                            const SizedBox(height: 6),
                            if (splitContent.imageLinks.isNotEmpty)
                              ImagesTileView(
                                images: splitContent.imageLinks,
                                //galleryBottomWidget: splitContent.content,
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  GestureDetector(
                                    onTap: () => {
                                      //_writeReply(context, widget.tweet)
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
                                          "wip",

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
                                        content: Text('repost implemented yet'),
                                        duration: Duration(seconds: 1),
                                      )),
                                    },
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          'assets/icons/retweet.svg',
                                          color: Palette.darkGray,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "" //widget.tweet.retweetsCount
                                              .toString(),
                                          style: const TextStyle(
                                              color: Palette.gray,
                                              fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // like button
                                  GestureDetector(
                                    onTap: () => {
                                      // copy to clipboard
                                      Clipboard.setData(ClipboardData(
                                          text:
                                              widget.note.toJson().toString())),
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
                                          "" //widget.tweet.likesCount
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
                                      openBottomSheetShare(context, widget.note)
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
    );
  }
}
