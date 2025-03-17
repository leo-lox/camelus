import 'dart:async';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/metadata_state_provider.dart';

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
  bool reportToCamelus = true;

  List<NostrTag> contentTags = [];

  final TextEditingController _textController = TextEditingController();
  String _reportReason = "";
  bool _reportSuccessful = false;
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
    //throw UnimplementedError();
    setState(() {
      _reportLoading = true;
    });
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _reportLoading = false;
      _reportSuccessful = true;
    });
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(metadataStateProvider(widget.userPubkey)).userMetadata;

    if (_reportSuccessful) {
      return Scaffold(
        backgroundColor: Palette.background,
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: 250,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "report send",
                    style: TextStyle(
                        color: Palette.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "thank you for your report",
                    style: TextStyle(color: Palette.lightGray, fontSize: 20),
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
              ),
            ),
          ),
        ),
      );
    }

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
                      Text(user?.name ?? user?.nip05 ?? widget.userPubkey,
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
                              onPressed: () => {_setReportReason("profanity")},
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
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: widget.postId != null
                                ? 'what is wrong with this post?'
                                : 'what is wrong with this user?',
                            hintStyle: const TextStyle(
                                color: Palette.white, letterSpacing: 1.1),
                            filled: true,
                            fillColor: Palette.extraDarkGray,
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              borderSide:
                                  BorderSide(color: Palette.extraDarkGray),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Palette.background),
                            ),
                          ),
                          style: const TextStyle(color: Palette.white),
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("additionally report to camelus"),
                          const SizedBox(width: 10),
                          Switch(
                            value: reportToCamelus,
                            onChanged: (value) {
                              setState(() {
                                reportToCamelus = value;
                              });
                            },
                            activeColor: Palette.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 40,
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: longButton(
                            name: widget.postId != null
                                ? "report post"
                                : "report user",
                            inverted: true,
                            loading: _reportLoading,
                            onPressed: () => {_reportPost()}),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
