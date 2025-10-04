import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/palette.dart';
import '../../../../domain_layer/entities/nostr_tag.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/metadata_state_provider.dart';
import '../../../providers/moderation/moderation_provider.dart';
import '../../../providers/ndk_provider.dart';

class BlockPage extends ConsumerStatefulWidget {
  final String userPubkey;
  final String? postId;

  const BlockPage({super.key, required this.userPubkey, this.postId});

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

  final List<String> reportReasons = [
    "impersonation",
    "spam",
    "illegal",
    "profanity",
    "nudity",
    "malware",
    "other",
  ];

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

  Future _submitReport() async {
    setState(() {
      _reportLoading = true;
    });
    final ndk = ref.read(ndkProvider);
    final myPubkey = ndk.accounts.getPublicKey();
    if (myPubkey == null) {
      throw Exception("cannot report without account");
    }

    final moderation = ref.read(moderationProvider);
    await moderation.report(
      pubkeySubmittingReport: myPubkey,
      reportReason: _reportReason,
      userReport: _textController.text,
      reportedPubkey: widget.userPubkey,
      postId: widget.postId,
      reportToCamelus: reportToCamelus,
    );

    setState(() {
      _reportLoading = false;
      _reportSuccessful = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user =
        ref.watch(metadataStateProvider(widget.userPubkey)).userMetadata;

    if (_reportSuccessful) {
      return Scaffold(
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
                  Text(
                    "report send",
                    style: TextStyle(
                        color: Paletter.getWhite(context),
                        fontSize: 30,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "thank you for your report",
                    style: TextStyle(color: Paletter.getLightGray(context), fontSize: 20),
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
      ),
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
                      Text('user',
                          style: TextStyle(
                              color: Paletter.getLightGray(context), fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(user?.name ?? user?.nip05 ?? widget.userPubkey,
                          style: TextStyle(
                              color: Paletter.getWhite(context),
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
                        children: reportReasons
                            .map((reason) => longButton(
                                  name: reason,
                                  onPressed: () => {_setReportReason(reason)},
                                  inverted: _reportReason == reason,
                                ))
                            .toList(),
                      ),

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
                            hintStyle: TextStyle(
                                color: Paletter.getWhite(context), letterSpacing: 1.1),
                            filled: true,
                            fillColor: Paletter.getExtraDarkGray(context),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              borderSide:
                                  BorderSide(color: Paletter.getExtraDarkGray(context)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.0)),
                              borderSide: BorderSide(color: Paletter.getBackground(context)),
                            ),
                          ),
                          style: TextStyle(color: Paletter.getWhite(context)),
                          minLines: 3,
                          maxLines: 5,
                        ),
                      ),
                      const SizedBox(height: 30),

                      Text(
                        "Reports are sent to the relays where you received the note from.",
                        style: TextStyle(color: Paletter.getGray(context)),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Additionally, report to camelus directly"),
                          const SizedBox(width: 10),
                          Switch(
                            value: reportToCamelus,
                            onChanged: (value) {
                              setState(() {
                                reportToCamelus = value;
                              });
                            },
                            activeThumbColor: Paletter.getWhite(context),
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
                            onPressed: () => {_submitReport()}),
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
