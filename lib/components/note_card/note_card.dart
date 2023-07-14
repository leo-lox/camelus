import 'dart:developer';
import 'dart:ui';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/components/bottom_sheet_share.dart';
import 'package:camelus/components/images_tile_view.dart';
import 'package:camelus/components/note_card/bottom_action_row.dart';
import 'package:camelus/components/note_card/bottom_sheet_more.dart';
import 'package:camelus/components/note_card/note_card_build_split_content.dart';
import 'package:camelus/components/write_post.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/models/post_context.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';
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
    if (!mounted) return;
    setState(() {});
  }

  late NostrService myNostrService;
  late UserMetadata metadata;
  late Future<Map<dynamic, dynamic>> myMetadata;
  late NoteCardSplitContent splitContent;

  void _splitContent() {
    splitContent = NoteCardSplitContent(
        widget.note, metadata, _openProfile, _splitContentStateUpdate);

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    metadata = ref.read(metadataProvider);
    myMetadata = metadata.getMetadataByPubkey(widget.note.pubkey);
    _splitContent();
  }

  @override
  void didUpdateWidget(covariant NoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _splitContent();
      metadata = ref.watch(metadataProvider);
      myMetadata = metadata.getMetadataByPubkey(widget.note.pubkey);
    }
  }

  @override
  Widget build(BuildContext context) {
    myNostrService = ref.watch(nostrServiceProvider);

    if (widget.note.pubkey == 'missing') {
      return SizedBox(
        height: 50,
        child: Center(
          child: Text(
            "Missing note:  ${widget.note.getDirectReply?.recommended_relay},  ${widget.note.getRootReply?.recommended_relay}",
            style: const TextStyle(color: Colors.purple, fontSize: 20),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
                    child: UserImage(
                        myMetadata: myMetadata, pubkey: widget.note.pubkey),
                  ),
                  Expanded(
                    // click container
                    child: Container(
                      margin: const EdgeInsets.only(left: 5, right: 10),
                      color: Palette.background,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _nameRow(myMetadata, myNostrService, context),
                            const SizedBox(height: 10),

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
                              child: BottomActionRow(
                                onComment: () {
                                  _writeReply(context, widget.note);
                                },
                                onLike: () {},
                                onRetweet: () {},
                                onShare: () {
                                  openBottomSheetShare(context, widget.note);
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            // show text if replies > 0
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(
          thickness: 0.3,
          color: Palette.darkGray,
        )
      ],
    );
  }

  Row _nameRow(Future<Map<dynamic, dynamic>> myMetadata,
      NostrService myNostrService, BuildContext context) {
    return Row(
        //mainAxisAlignment: MainAxisAlignment.end,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FutureBuilder<Map>(
              future: myMetadata,
              builder: (BuildContext context, AsyncSnapshot<Map> snapshot) {
                var name = "";

                if (snapshot.hasData) {
                  var npubHr =
                      Helpers().encodeBech32(widget.note.pubkey, "npub");
                  var npubHrShort =
                      "${npubHr.substring(0, 4)}...${npubHr.substring(npubHr.length - 4)}";
                  name = snapshot.data?["name"] ?? npubHrShort;
                  _checkNip05(snapshot.data?["nip05"] ?? "", widget.note.pubkey,
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
                      constraints:
                          const BoxConstraints(minWidth: 5, maxWidth: 150),
                      child: RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 17),
                        ),
                      ),
                    ),
                    if (nip05verified.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 0, left: 5),
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
              timeago.format(DateTime.fromMillisecondsSinceEpoch(
                  widget.note.created_at * 1000)),
              style: const TextStyle(color: Palette.gray, fontSize: 12),
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
        ]);
  }
}

void _writeReply(ctx, NostrNote note) {
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
                  context: PostContext(replyToNote: note),
                )),
          ));
}
