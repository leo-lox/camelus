import 'dart:developer';
import 'dart:io';

import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:camelus/config/palette.dart';
import 'package:camelus/data_layer/models/post_context.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/usecases/remove_image_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/picture.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:camelus/presentation_layer/providers/search_provider.dart';
import 'package:camelus/presentation_layer/providers/write_post_state.provider.dart';
import 'package:camelus/config/default_suggestions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mentions/flutter_mentions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'post_overflow.dart';
import 'write_post/post_settings_dialog.dart';

class WritePost extends ConsumerStatefulWidget {
  final PostContext? context;

  const WritePost({super.key, this.context});

  @override
  ConsumerState<WritePost> createState() => _WritePostState();
}

class _WritePostState extends ConsumerState<WritePost> {
  //final TextEditingController _textEditingController = TextEditingController();
  final GlobalKey<FlutterMentionsState> _textEditingControllerKey =
      GlobalKey<FlutterMentionsState>();
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _mentionsSearchResults = [];
  List<Map<String, dynamic>> _mentionsSearchResultsHashTags = [];

  _addImage() async {
    final ImagePicker picker = ImagePicker();
    final result = await picker.pickMultiImage();

    try {
      for (final image in result) {
        final myImage =
            await RemoveImageMetadata.fileToMemFile(File(image.path));
        ref.read(writePostStateProvider.notifier).addImage(myImage);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.unsupportedImageFormat),
        ),
      );
    }
  }

  _searchMentions(search) async {
    final writePostState = ref.read(writePostStateProvider);
    final searchService = ref.read(searchProvider);
    List<Map<String, dynamic>> results = [];

    final rawResults = await searchService.searchMetadata(search);

    for (final rawResult in rawResults) {
      final result = {
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
    for (final mention in writePostState.mentionedInPost) {
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

    results = defaultHashtagSuggestions;

    setState(() {
      _mentionsSearchResultsHashTags = results;
    });
  }

  void _initServices() async {}

  @override
  void initState() {
    super.initState();
    // focus text field
    _focusNode.requestFocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(writePostStateProvider.notifier)
          .updateReplyToNote(widget.context?.replyToNote);

      _textEditingControllerKey.currentState?.controller?.text =
          ref.read(writePostStateProvider).markupText;
    });
  }

  @override
  didChangeDependencies() {
    super.didChangeDependencies();
    _initServices();
  }

  @override
  void dispose() {
    //_textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final writePostState = ref.watch(writePostStateProvider);
    final writePostNotifier = ref.watch(writePostStateProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // horizontal line fading out to both sides

        if (writePostState.isError)
          Column(
            children: [
              const SizedBox(
                height: 20,
              ),
              Text(AppLocalizations.of(context)!.error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  )),
              SizedBox(
                height: 5,
              ),
              Text(
                writePostState.errorText,
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),

        Container(
          width: double.infinity,
          //height: MediaQuery.of(context).size.height * 0.4,
          padding: const EdgeInsets.only(top: 0, left: 0, right: 0),
          alignment: Alignment.topLeft,
          // round  corners
          decoration: BoxDecoration(
            color: Paletter.getExtraDarkGray(context),
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
                replyToPubkey: writePostState.replyToNote?.pubkey,
                submitLoading: writePostState.isSubmitting,
                submitPostCallback: () => writePostNotifier.submitPost().then(
                  (value) {
                    if (!mounted) return;
                    context.pop();
                  },
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              // large text field
              _writingArea(),
              // image preview
              if (writePostState.images.isNotEmpty) _previewImages(),

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
    final images = ref.watch(writePostStateProvider).images;
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (BuildContext context, int index) {
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(left: 10, right: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    images[index].bytes,
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
                      images.removeAt(index);
                    });
                  }),
                  child: SvgPicture.asset(
                    height: 25,
                    'assets/icons/x.svg',
                    colorFilter: ColorFilter.mode(
                      Paletter.getGray(context),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _bottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 10,
            ),
            _buildActionButton(
              icon: Icon(
                PhosphorIcons.image(),
                color: Paletter.getGray(context),
                size: 25,
              ),
              onPressed: _addImage,
            ),
            _buildActionButton(
              icon: Icon(
                PhosphorIcons.gearSix(),
                color: Paletter.getGray(context),
                size: 25,
              ),
              onPressed: () => _showPostSettingsDialog(context),
            ),
          ],
        ),

        // Character counter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: PostOverflowIndicator(
            characterCount: ref.watch(writePostStateProvider).markupText.length,
            maxLength: 280,
          ),
        ),
      ],
    );
  }

  void _showPostSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PostSettings();
      },
    );
  }

  Widget _buildActionButton({
    required Icon icon,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: icon,
    );
  }

  Container _writingArea() {
    return Container(
      //height: 200,
      padding: const EdgeInsets.only(left: 20, right: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        //border: Border.all(color: Theme.of(context).colorScheme.primary), //debug
      ),
      child: FlutterMentions(
        key: _textEditingControllerKey,
        keyboardType: TextInputType.multiline,
        keyboardAppearance: Brightness.dark,
        suggestionPosition: SuggestionPosition.Top,
        focusNode: _focusNode,
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface, fontSize: 21),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: AppLocalizations.of(context)!.whatsOnYourMind,
          hintStyle: TextStyle(
            color: Paletter.getGray(context),
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
          // triggers when something is typed in the text fields
          ref.read(writePostStateProvider.notifier).updateMarkup(p0);
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
          color: Paletter.getExtraDarkGray(context),
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
                          color: Theme.of(context).colorScheme.surface,
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
                          style: TextStyle(
                            color: Paletter.getLightGray(context),
                            fontSize: 20,
                          ),
                        ),
                        Text(
                          '${data['nip05'] ?? ""}',
                          style: TextStyle(
                            color: Paletter.getGray(context),
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
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
            data: _mentionsSearchResults,
          ),
          Mention(
            suggestionBuilder: (data) {
              return Container(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 20.0,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          data['display'] != null ? "#${data['display']}" : "",
                          style: TextStyle(
                            color: Paletter.getLightGray(context),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
            trigger: "#",
            matchAll: true,
            disableMarkup: true,
            style: TextStyle(color: Colors.purple),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /// close button
          IconButton(
            onPressed: (() {
              ref.read(writePostStateProvider.notifier).clearPost();
              context.pop();
            }),
            icon: SvgPicture.asset(
              height: 25,
              'assets/icons/x.svg',
              colorFilter: ColorFilter.mode(
                Paletter.getGray(context),
                BlendMode.srcIn,
              ),
            ),
          ),
          if (replyToPubkey == null)
            Text(
              AppLocalizations.of(context)!.writePost,
              style: TextStyle(
                color: Paletter.getLightGray(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          if (replyToPubkey != null)
            Expanded(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.6,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: Text(
                    AppLocalizations.of(context)!.replyTo(
                        metadata?.name ?? getPubkeyHrShort(replyToPubkey!)),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: Paletter.getLightGray(context),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // if submitLoading is true, show spinner
          !submitLoading
              ? IconButton(
                  onPressed: (() {
                    submitPostCallback();
                  }),
                  icon: SvgPicture.asset(
                    height: 25,
                    'assets/icons/paper-plane-tilt.svg',
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary, BlendMode.srcIn),
                  ),
                )
              : Lottie.asset(
                  'assets/lottie/spinner.json',
                  height: 40,
                  width: 64,
                  alignment: Alignment.topCenter,
                )
        ],
      ),
    );
  }
}
