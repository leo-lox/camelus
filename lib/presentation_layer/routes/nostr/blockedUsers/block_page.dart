import 'dart:async';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlockPage extends ConsumerStatefulWidget {
  String userPubkey;
  String? postId;

  BlockPage({super.key, required this.userPubkey, this.postId});

  @override
  ConsumerState<BlockPage> createState() => _BlockPageState();
}

class _BlockPageState extends ConsumerState<BlockPage> {
  bool isUserBlocked = false;
  bool requestLoading = false;

  List<NostrTag> contentTags = [];

  final TextEditingController _textController = TextEditingController();
  String _reportReason = "";
  bool _postReported = false;
  bool _reportLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _blockUser(
    String pubkey,
  ) async {
    throw UnimplementedError();
  }

  void _unblockUser(
    String pubkey,
  ) async {
    throw UnimplementedError();
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
    throw UnimplementedError();
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
                      Text("unimplemented",
                          style: TextStyle(
                              color: Palette.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FutureBuilder(
                      future: Future.delayed(Duration(seconds: 1)),
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
