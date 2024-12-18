import 'dart:developer';
import 'dart:io';

import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/atoms/picture.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/edit_relays_provider.dart';
import 'package:camelus/presentation_layer/providers/event_signer_provider.dart';
import 'package:camelus/presentation_layer/providers/file_upload_provider.dart';
import 'package:camelus/presentation_layer/providers/get_notes_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/data_layer/models/post_context.dart';

import '../../domain_layer/entities/mem_file.dart';
import '../../domain_layer/usecases/remove_image_metadata.dart';

class WritePost extends ConsumerStatefulWidget {
  final PostContext? context;

  const WritePost({super.key, this.context});

  @override
  ConsumerState<WritePost> createState() => _WritePostState();
}

class _WritePostState extends ConsumerState<WritePost> {
  final TextEditingController _textEditingController = TextEditingController();
  final GlobalKey<FlutterMentionsState> _textEditingControllerKey =
      GlobalKey<FlutterMentionsState>();
  final FocusNode _focusNode = FocusNode();

  bool submitLoading = false;

  final List<MemFile> _images = [];
  List<Map<String, dynamic>> _mentionsSearchResults = [];
  List<Map<String, dynamic>> _mentionsSearchResultsHashTags = [];
  List<String> _mentionedInPost = [];
  List<String> _hashtagsInPost = [];

  _addImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      dialogTitle: "select image",
    );

    if (result != null) {
      try {
        final myImage = await RemoveImageMetadata.fileToMemFile(
            File(result.files.single.path!));
        setState(() {
          _images.add(myImage);
        });
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('unspoorted image format'),
          ),
        );
      }
    } else {
      // User canceled the picker
      return;
    }
  }

  _searchMentions(search) async {
    List<Map<String, dynamic>> results = [];

    var rawResults = []; //_search.searchUsersMetadata(search);
    for (var rawResult in rawResults) {
      var result = {
        "id": rawResult.pubkey,
        "pubkey": rawResult.pubkey,
        "display": rawResult.name ?? "",
        "name": rawResult.name ?? "",
        "picture": rawResult.picture ?? "",
        "nip05": rawResult.nip05 ?? "",
      };
      results.add(result);
    }

    // keep data from already mentioned users
    for (var mention in _mentionedInPost) {
      if (results.any((element) => element['id'] == mention)) {
        continue;
      }

      // find user in _mentionsSearchResults and add it to results
      // to keep the data

      var user = _mentionsSearchResults.firstWhere((element) {
        return element['id'] == mention;
      },
          // should not happen
          orElse: () => {
                "id": mention,
                "display": mention,
                "picture": "",
                "nip05": "",
              });

      results.add(user);
    }

    setState(() {
      _mentionsSearchResults = results;
    });
  }

  /// todo: build this properly
  _searchHashtags(String search) async {
    List<Map<String, dynamic>> results = [];

    results = [
      {
        "id": "todo",
        "display": search,
      }
    ];

    setState(() {
      _mentionsSearchResultsHashTags = results;
    });
  }

  _extractMentions(String markupText) {
    final mentionKeys = <String>[];
    final keyRegex = RegExp(r'@\[__(.*?)__\]');

    markupText.replaceAllMapped(keyRegex, (match) {
      mentionKeys.add(match.group(1)!);
      return '';
    });

    setState(() {
      _mentionedInPost = mentionKeys;
    });
  }

  _extractHashtags(String markupText) {
    final hashtagKeys = <String>[];
    final keyRegex = RegExp(r'#\w+');

    markupText.replaceAllMapped(keyRegex, (match) {
      hashtagKeys.add(match.group(0)!);
      return '';
    });

    setState(() {
      _hashtagsInPost = hashtagKeys;
    });
  }

  _submitPost() async {
    var textController = _textEditingControllerKey.currentState!.controller;

    if (textController!.text == "") {
      return;
    }

    setState(() {
      submitLoading = true;
    });

    var markupText = textController.markupText;

    // extract mentions from markupText

    final mentionKeys = <String>[];
    final keyRegex = RegExp(r'@\[__(.*?)__\]');

    String output = markupText.replaceAllMapped(keyRegex, (match) {
      mentionKeys.add(match.group(1)!);
      var userHex = match.group(1)!;

      var nprofile =
          NprofileHelper().mapToBech32({'pubkey': userHex, 'relays': []});
      return 'nostr:$nprofile ';
    });

    output = output.replaceAllMapped(RegExp(r'\(__.*?\)'), (match) {
      return '';
    });

    var content = output;

    List<NostrTag> tags = [];

    if (widget.context != null) {
      var replyIsReplyToRoot = widget.context!.replyToNote.getRootReply;
      if (replyIsReplyToRoot != null) {
        var tag = NostrTag(
          type: "e",
          value: replyIsReplyToRoot.value,
          recommended_relay: "",
          marker: "root",
        );
        tags.add(tag);
      } else {
        // is reply to root
        var tag = NostrTag(
          type: "e",
          value: widget.context!.replyToNote.id,
          recommended_relay: "",
          marker: "root",
        );
        tags.add(tag);
        var tagPubkey = NostrTag(
          type: "p",
          value: widget.context!.replyToNote.pubkey,
          recommended_relay: "",
          marker: "root",
        );
        tags.add(tagPubkey);
      }

      // add previous tweet tags
      for (NostrTag tag in widget.context!.replyToNote.tags) {
        if (tag.type == "e") {
          if (tag.marker == "root" || tag.marker == "reply") {
            continue;
          }
          if (!(tags.map((e) => e.value).contains(tag.value))) {
            tags.add(tag);
          }
        }
        if (tag.type == "p") {
          if (tag.marker == "root" || tag.marker == "reply") {
            continue;
          }

          tags.add(tag);
        }
      }

      if (mentionKeys.isNotEmpty) {
        for (int i = 0; i < mentionKeys.length; i++) {
          var pubkey = mentionKeys[i];
          final editRelayProvider = ref.watch(editRelaysProvider);

          var potentialRelays =
              await editRelayProvider.getRelayHintsInbox(pubkey);

          tags.add(NostrTag(
            type: "p",
            value: pubkey,
            recommended_relay: potentialRelays.firstOrNull?.url ?? "",
            marker: "mention",
          ));
        }
      }

      if (widget.context != null) {
        var tag = NostrTag(
          type: "e",
          value: widget.context!.replyToNote.id,
          recommended_relay: "",
          marker: "reply",
        );
        tags.add(tag);

        var tagPubkey = NostrTag(
          type: 'p',
          value: widget.context!.replyToNote.pubkey,
          recommended_relay: '',
          marker: 'reply',
        );
        tags.add(tagPubkey);
      }
    }

    // add hashtags
    for (var hashtag in _hashtagsInPost) {
      tags.add(
        NostrTag(
          type: "t",
          value: hashtag.toLowerCase().substring(1),
        ),
      );
    }

    // upload images
    List<String> imageUrls = [];
    for (var image in _images) {
      try {
        var url = await ref.watch(fileUploadProvider).uploadImage(image);
        imageUrls.add(url);
      } catch (e) {
        log("errUploadImage:  ${e.toString()}");
      }
    }

    // add image urls to content
    content += "\n";
    for (var url in imageUrls) {
      content += " $url";
    }

    final notesP = ref.watch(getNotesProvider);

    final signerP = ref.watch(eventSignerProvider);
    if (signerP == null) {
      _showErrorMsg("no signer");
      return;
    }
    final pubkey = signerP.getPublicKey();

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await notesP
        .broadcastNote(NostrNote(
      id: '',
      pubkey: pubkey,
      created_at: now,
      kind: 1,
      content: content,
      sig: '',
      tags: tags,
    ))
        .onError(
      (error, stackTrace) {
        _showErrorMsg('Error broadcasting note: $error');
        return;
      },
    );

    setState(() {
      submitLoading = false;
    });

    // wait for x seconds
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      // close modal
      Navigator.pop(context);
    });
  }

  _showErrorMsg(String msg) {
    // alert dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("error"),
          content: Text(msg),
          actions: [
            TextButton(
              child: const Text("ok"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _initServices() async {}

  @override
  void initState() {
    super.initState();
    // focus text field
    _focusNode.requestFocus();
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    _initServices();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // horizontal line fading out to both sides

        Container(
          width: double.infinity,
          //height: MediaQuery.of(context).size.height * 0.4,
          padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
          alignment: Alignment.topLeft,
          // round  corners
          decoration: const BoxDecoration(
            color: Palette.extraDarkGray,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                height: 5,
              ),

              _TopBar(
                replyToPubkey: widget.context?.replyToNote.pubkey,
                submitLoading: submitLoading,
                submitPostCallback: _submitPost,
              ),
              const SizedBox(
                height: 20,
              ),
              // large text field
              _writingArea(),
              // image preview
              if (_images.isNotEmpty) _previewImages(),

              // bottom row
              _bottomRow(),
              // to left

              const SizedBox(
                height: 5,
              ),
            ],
          ),
        ),
      ],
    );
  }

  SizedBox _previewImages() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length,
        itemBuilder: (BuildContext context, int index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    _images[index].bytes,
                    fit: BoxFit.cover,
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: TextButton(
                  onPressed: (() {
                    setState(() {
                      _images.removeAt(index);
                    });
                  }),
                  child: SvgPicture.asset(
                    height: 25,
                    'assets/icons/x.svg',
                    color: Palette.gray,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Column _bottomRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // add image
            TextButton(
              onPressed: (() {
                _addImage();
              }),
              child: SvgPicture.asset(
                height: 25,
                'assets/icons/image.svg',
                color: Palette.gray,
              ),
            ),
            // add video

            //TextButton(
            //  onPressed: (() {
            //    // _addVideo();
            //  }),
            //  child: SvgPicture.asset(
            //    height: 25,
            //    'assets/icons/file-video.svg',
            //    color: Palette.gray,
            //  ),
            //),

            // on bottom
          ],
        ),
        if (_images.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 10, right: 10),
            child: const Text(
              "provided by nostr.build",
              style: TextStyle(color: Palette.lightGray, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Container _writingArea() {
    return Container(
      //height: 200,
      padding: const EdgeInsets.only(left: 20, right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        //border: Border.all(color: Palette.primary), //debug
      ),
      child: FlutterMentions(
        key: _textEditingControllerKey,
        keyboardType: TextInputType.multiline,
        keyboardAppearance: Brightness.dark,
        suggestionPosition: SuggestionPosition.Top,
        focusNode: _focusNode,
        style: const TextStyle(color: Palette.white, fontSize: 21),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "What's on your mind?",
          hintStyle: TextStyle(
            color: Palette.gray,
            fontSize: 20,
          ),
        ),
        maxLines: 10,
        minLines: 5,
        onMentionAdd: (p0) {
          // only triggers when user selects a mention from the list
          log("mention added: $p0");
        },
        onMarkupChanged: (p0) {
          // triggers when something is typed in the text field
          _extractMentions(p0);
          _extractHashtags(p0);
        },
        onSearchChanged: (String trigger, search) {
          if (search.isNotEmpty && trigger == "@") {
            log("message: $search");
            _searchMentions(search);
          }
          if (search.isNotEmpty && trigger == "#") {
            _searchHashtags(search);
          }
        },
        suggestionListDecoration: BoxDecoration(
          color: Palette.extraDarkGray,
          borderRadius: BorderRadius.circular(20),
        ),
        mentions: [
          Mention(
            suggestionBuilder: (data) {
              return Container(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: <Widget>[
                    ClipOval(
                      child: SizedBox.fromSize(
                        size: const Size.fromRadius(30), // Image radius
                        child: Container(
                          color: Palette.background,
                          child: simplePicture(data['picture'], data['id']),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 20.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          data['name'] ?? "",
                          style: const TextStyle(
                            color: Palette.lightGray,
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '${data['nip05'] ?? ""}',
                          style: const TextStyle(
                            color: Palette.gray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
            trigger: "@",
            matchAll: true,
            disableMarkup: false,
            style: const TextStyle(color: Palette.primary),
            data: _mentionsSearchResults,
          ),
          Mention(
            suggestionBuilder: (data) {
              return Container();
            },
            trigger: "#",
            matchAll: true,
            disableMarkup: true,
            style: const TextStyle(color: Palette.purple),
            data: _mentionsSearchResultsHashTags,
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  final String? replyToPubkey;
  final bool submitLoading;
  final Function submitPostCallback;

  const _TopBar({
    this.replyToPubkey,
    required this.submitLoading,
    required this.submitPostCallback,
  });

  getPubkeyHrShort(String pubkey) {
    final pubkeyHr = Helpers().encodeBech32(pubkey, "npub");
    final pubkeyHrShort =
        "${pubkeyHr.substring(0, 5)}...${pubkeyHr.substring(pubkeyHr.length - 5)}";
    return pubkeyHrShort;
  }

  @override
  build(BuildContext context, WidgetRef ref) {
    UserMetadata? metadata;

    if (replyToPubkey != null) {
      metadata = ref.watch(metadataStateProvider(replyToPubkey!)).userMetadata;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton(
          onPressed: (() {
            Navigator.pop(context);
          }),
          child: SvgPicture.asset(
            height: 25,
            'assets/icons/x.svg',
            color: Palette.gray,
          ),
        ),
        if (replyToPubkey == null)
          const Text(
            "write a post",
            style: TextStyle(
              color: Palette.lightGray,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (replyToPubkey != null)
          Column(
            children: [
              // get metadata

              SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Container(
                  margin: const EdgeInsets.only(left: 10, right: 10, top: 5),
                  child: Text(
                    "reply to ${metadata?.name ?? getPubkeyHrShort(replyToPubkey!)}",
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: const TextStyle(
                      color: Palette.lightGray,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              /// check if replying to multiple people
              // if ((Helpers()
              //         .getPubkeysFromTags(
              //             widget.context?.replyToTweet.tags ?? [])
              //         .length >
              //     1))
              //   Text(
              //     "and ${Helpers().getPubkeysFromTags(widget.context?.replyToTweet.tags ?? []).length - 1} more",
              //     style: const TextStyle(
              //       color: Palette.lightGray,
              //       fontSize: 16,
              //       fontWeight: FontWeight.normal,
              //     ),
              //   ),
            ],
          ),
        // if submitLoading is true, show spinner
        !submitLoading
            ? TextButton(
                onPressed: (() {
                  submitPostCallback();
                }),
                child: SvgPicture.asset(
                  height: 25,
                  'assets/icons/paper-plane-tilt.svg',
                  color: Palette.primary,
                ),
              )
            : Lottie.asset(
                'assets/lottie/spinner.json',
                height: 40,
                width: 64,
                alignment: Alignment.topCenter,
              )
      ],
    );
  }
}
