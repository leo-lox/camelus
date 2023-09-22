import 'dart:async';
import 'package:camelus/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/models/nostr_request_event.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/block_mute_provider.dart';
import 'package:camelus/providers/key_pair_provider.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/relay_provider.dart';
import 'package:camelus/services/nostr/metadata/block_mute_service.dart';
import 'package:camelus/services/nostr/relays/relay_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BlockPage extends ConsumerStatefulWidget {
  String userPubkey;
  String? postId;

  BlockPage({Key? key, required this.userPubkey, this.postId})
      : super(key: key);

  @override
  ConsumerState<BlockPage> createState() => _BlockPageState();
}

class _BlockPageState extends ConsumerState<BlockPage> {
  bool isUserBlocked = false;
  bool requestLoading = false;

  List<NostrTag> contentTags = [];

  Completer initDone = Completer();

  /// services
  late final BlockMuteService blockMuteService;
  late final RelayCoordinator relayService;
  late final KeyPairWrapper keyService;

  final TextEditingController _textController = TextEditingController();
  String _reportReason = "";
  bool _postReported = false;
  bool _reportLoading = false;

  @override
  void initState() {
    super.initState();
    _initListener();
  }

  void _initListener() async {
    blockMuteService = await ref.read(blockMuteProvider.future);
    relayService = ref.read(relayServiceProvider);
    keyService = await ref.read(keyPairProvider.future);

    // get current state
    contentTags = blockMuteService.contentObj;

    initDone.complete();
    _checkBlockMuteState();

    // listen to state changes
    blockMuteService.blockListStream.listen((event) {
      contentTags = event;
      _checkBlockMuteState();
    });
  }

  _checkBlockMuteState() {
    for (var tag in contentTags) {
      if (tag.value == widget.userPubkey) {
        setState(() {
          isUserBlocked = true;
        });

        return;
      }
    }
    if (mounted) {
      setState(() {
        isUserBlocked = false;
      });
    }
  }

  void _blockUser(
    String pubkey,
  ) async {
    setState(() {
      requestLoading = true;
    });

    await blockMuteService.blockUser(
        pubkey: pubkey, relayService: relayService);
    setState(() {
      requestLoading = false;
    });
  }

  void _unblockUser(
    String pubkey,
  ) async {
    setState(() {
      requestLoading = true;
    });
    await blockMuteService.unBlockUser(
        pubkey: pubkey, relayService: relayService);
    setState(() {
      requestLoading = false;
    });
  }

  void _setReportReason(String reason) {
    if (reason == _reportReason) {
      reason = "";
    }
    setState(() {
      _reportReason = reason;
    });
  }

  Future _reportPost() async {
    setState(() {
      _reportLoading = true;
    });

    List<NostrTag> reportTags = [
      NostrTag(type: "p", value: widget.userPubkey),
      NostrTag(type: "e", value: widget.postId!, marker: _reportReason),
    ];

    final NostrRequestEventBody newReportBody = NostrRequestEventBody(
      pubkey: keyService.keyPair!.publicKey,
      kind: 1984,
      tags: reportTags,
      content: _textController.text,
      privateKey: keyService.keyPair!.privateKey,
    );

    var myReport = NostrRequestEvent(body: newReportBody);
    var relays = ref.watch(relayServiceProvider);
    List<String> results = await relays.write(request: myReport);

    setState(() {
      _reportLoading = false;
      _postReported = true;
    });
    return results;
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('block/report'),
        backgroundColor: Palette.background,
      ),
      backgroundColor: Palette.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // block user
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('user',
                          style: TextStyle(
                              color: Palette.lightGray, fontSize: 20)),
                      const SizedBox(width: 10),
                      FutureBuilder<DbUserMetadata?>(
                        future:
                            metadata.getMetadataByPubkey(widget.userPubkey),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Text(
                              snapshot.data?.name ?? widget.userPubkey,
                              style: const TextStyle(
                                  color: Palette.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold),
                            );
                          }
                          return Container();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                      future: initDone.future,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SizedBox(
                            height: 40,
                            width: MediaQuery.of(context).size.width * 0.75,
                            child: longButton(
                                name: "loading",
                                loading: true,
                                onPressed: () {}),
                          );
                        }

                        return SizedBox(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: longButton(
                              name: isUserBlocked ? "unblock" : "block",
                              inverted: !isUserBlocked,
                              loading: requestLoading,
                              onPressed: () {
                                if (isUserBlocked) {
                                  _unblockUser(widget.userPubkey);
                                } else {
                                  _blockUser(widget.userPubkey);
                                }
                                setState(() {
                                  isUserBlocked = !isUserBlocked;
                                });
                              }),
                        );
                      }),
                  const SizedBox(height: 10),
                  if (widget.postId != null && !_postReported)
                    Column(
                      children: [
                        const SizedBox(height: 100),
                        //text user input

                        GridView.count(
                            crossAxisCount: 2,
                            childAspectRatio: 4.5 / 1,
                            shrinkWrap: true,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            children: [
                              longButton(
                                name: "impersonation",
                                onPressed: () =>
                                    {_setReportReason("impersonation")},
                                inverted: _reportReason == "impersonation",
                              ),
                              longButton(
                                name: "spam",
                                onPressed: () => {_setReportReason("spam")},
                                inverted: _reportReason == "spam",
                              ),
                              longButton(
                                name: "illegal",
                                onPressed: () => {_setReportReason("illegal")},
                                inverted: _reportReason == "illegal",
                              ),
                              longButton(
                                name: "profanity",
                                onPressed: () =>
                                    {_setReportReason("profanity")},
                                inverted: _reportReason == "profanity",
                              ),
                              longButton(
                                name: "nudity",
                                onPressed: () => {_setReportReason("nudity")},
                                inverted: _reportReason == "nudity",
                              ),
                            ]),

                        const SizedBox(height: 20),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.90,
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'what is wrong with this post?',
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: longButton(
                              name: "report post",
                              inverted: true,
                              loading: _reportLoading,
                              onPressed: () => {_reportPost()}),
                        ),
                      ],
                    ),
                  if (_postReported)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 100),
                        const Text(
                          "post reported",
                          style: TextStyle(
                              color: Palette.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "thank you for reporting this post",
                          style:
                              TextStyle(color: Palette.lightGray, fontSize: 20),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 40,
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: longButton(
                              inverted: true,
                              name: "go back",
                              onPressed: () => {
                                    Navigator.pop(context),
                                  }),
                        ),
                      ],
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
