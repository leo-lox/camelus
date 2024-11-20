import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/domain_layer/usecases/get_user_metadata.dart';
import 'package:camelus/presentation_layer/components/images_tile_view.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_reference.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';

final profilePattern = RegExp(r"nostr:(nprofile|npub)[a-zA-Z0-9]+");
final notePattern = RegExp(r"nostr:(note|nevent)[a-zA-Z0-9]+");

/// this class is responsible for building the content of a note
class NoteCardSplitContent extends ConsumerStatefulWidget {
  final NostrNote note;
  final Function(String) profileCallback;
  final Function(String) hashtagCallback;

  const NoteCardSplitContent({
    super.key,
    required this.note,
    required this.hashtagCallback,
    required this.profileCallback,
  });

  @override
  ConsumerState<NoteCardSplitContent> createState() =>
      _NoteCardSplitContentState();
}

class _NoteCardSplitContentState extends ConsumerState<NoteCardSplitContent> {
  final Map<String, dynamic> _tagsMetadata = {};

  List<String> imageLinks = [];

  _NoteCardSplitContentState();

  List<Widget> body = [];

  @override
  void initState() {
    super.initState();

    imageLinks = _extractImages(widget.note);
    body = _buildContent(widget.note.content);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(NoteCardSplitContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      imageLinks = _extractImages(widget.note);
      body = _buildContent(widget.note.content);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 0,
      runSpacing: 4,
      direction: Axis.horizontal,
      verticalDirection: VerticalDirection.down,
      children: body,
    );
  }

  List<Widget> _buildContent(String content) {
    List<Widget> widgets = [];
    List<String> lines = content.split("\n");
    for (var line in lines) {
      if (line == "") {
        //widgets.add(_buildText("\n"));
        widgets.add(const SizedBox(height: 7, width: 1000));
        continue;
      }
      List<String> words = line.split(" ");
      for (var word in words) {
        if (profilePattern.hasMatch(word)) {
          widgets.add(ProfileLink(
            profileCallback: widget.profileCallback,
            word: word,
          ));
        } else if (notePattern.hasMatch(word)) {
          widgets.add(NoteCardReference(word: word));
        } else if (word.startsWith("#[")) {
          widgets.add(LegacyMentionHashtag(
              note: widget.note,
              tagsMetadata: _tagsMetadata,
              profileCallback: widget.profileCallback,
              word: word));
        } else if (word.startsWith("#")) {
          widgets.add(
              HashtagLink(hashtagCallback: widget.hashtagCallback, word: word));
        } else if (word.startsWith("http")) {
          widgets.add(HttpLink(imageLinks: imageLinks, word: word));
        } else {
          widgets.add(DisplayText(word: word));
        }
        widgets.add(const DisplayText(word: " "));
      }
      widgets.removeLast(); // remove last space
      //widgets.add(_buildText("\n")); // add back the original line break
      widgets.add(const SizedBox(
        height: 7,
      ));
    }

    if (imageLinks.isNotEmpty) {
      widgets.add(
        ImagesTileView(
          images: imageLinks,
          //galleryBottomWidget: splitContent.content,
        ),
      );
    }

    return widgets;
  }

  List<String> _extractImages(NostrNote note) {
    List<String> imageLinks = [];
    RegExp exp = RegExp(r"(https?:\/\/[^\s]+)");
    Iterable<RegExpMatch> matches = exp.allMatches(note.content);
    for (var match in matches) {
      var link = match.group(0);
      if (link!.endsWith(".jpg") ||
          link.endsWith(".jpeg") ||
          link.endsWith(".png") ||
          link.endsWith(".webp") ||
          link.contains(".avif") ||
          link.endsWith(".gif")) {
        imageLinks.add(link);
      }
    }

    return imageLinks;
  }
}

class DisplayText extends StatelessWidget {
  const DisplayText({
    super.key,
    required this.word,
  });

  final String word;

  @override
  Widget build(BuildContext context) {
    return Text(
      word,
      style: const TextStyle(color: Palette.lightGray, fontSize: 17),
    );
  }
}

class HttpLink extends StatelessWidget {
  const HttpLink({
    super.key,
    required this.imageLinks,
    required this.word,
  });

  final List<String> imageLinks;
  final String word;

  @override
  Widget build(BuildContext context) {
    if (imageLinks.contains(word)) {
      return const SizedBox(height: 0, width: 0);
    }

    return GestureDetector(
      onTap: () {
        launchUrlString(word, mode: LaunchMode.externalApplication);
      },
      child: Text(
        word,
        style: const TextStyle(color: Palette.primary, fontSize: 17),
      ),
    );
  }
}

class HashtagLink extends StatelessWidget {
  const HashtagLink({
    super.key,
    required Function(String p1) hashtagCallback,
    required this.word,
  }) : _hashtagCallback = hashtagCallback;

  final Function(String p1) _hashtagCallback;
  final String word;

  @override
  Widget build(BuildContext context) {
    String hashtag = word.substring(1);

    return GestureDetector(
      onTap: () {
        _hashtagCallback(hashtag);
      },
      child: Text(
        word,
        style: const TextStyle(color: Palette.primary, fontSize: 17),
      ),
    );
  }
}

class LegacyMentionHashtag extends ConsumerWidget {
  const LegacyMentionHashtag({
    super.key,
    required NostrNote note,
    required Map<String, dynamic> tagsMetadata,
    required Function(String p1) profileCallback,
    required this.word,
  })  : _note = note,
        _tagsMetadata = tagsMetadata,
        _profileCallback = profileCallback;

  final NostrNote _note;
  final Map<String, dynamic> _tagsMetadata;

  final Function(String p1) _profileCallback;
  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var indexString = word.replaceAll("#[", "").replaceAll("]", "");
    int index;
    try {
      index = int.parse(indexString);
    } catch (e) {
      return const SizedBox(height: 0, width: 0);
    }

    var tag = _note.tags[index];

    if (tag.type != 'p') {
      return const SizedBox(height: 0, width: 0);
    }

    var pubkeyBech = Helpers().encodeBech32(tag.value, "npub");
    // first 5 chars then ... then last 5 chars
    var pubkeyHr =
        "${pubkeyBech.substring(0, 5)}...${pubkeyBech.substring(pubkeyBech.length - 5)}";
    _tagsMetadata[tag.value] = pubkeyHr;

    final metadata = ref.watch(metadataStateProvider(tag.value)).userMetadata;

    return GestureDetector(
      onTap: () {
        _profileCallback(tag.value);
      },
      child: Text(
        metadata != null ? "@${metadata.name ?? pubkeyHr}" : "@$pubkeyHr",
        style: const TextStyle(color: Palette.primary, fontSize: 17),
      ),
    );
  }
}

class ProfileLink extends ConsumerWidget {
  const ProfileLink({
    super.key,
    required Function(String p1) profileCallback,
    required this.word,
  }) : _profileCallback = profileCallback;

  final Function(String p1) _profileCallback;
  final String word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var group = profilePattern.allMatches(word);
    var match = group.first;
    var cleaned = match.group(0);

    if (cleaned == "") return const SizedBox(height: 0, width: 0);

    final myMatch = cleaned!.replaceAll("nostr:", "");
    String myPubkeyHex = "";
    String pubkeyBech = "";

    if (myMatch.contains("nprofile")) {
      // remove the "nostr:" part

      Map<String, dynamic> nProfileDecode =
          NprofileHelper().bech32toMap(myMatch);

      final List<String> myRelays = nProfileDecode['relays'];
      myPubkeyHex = nProfileDecode['pubkey'];
      pubkeyBech = Helpers().encodeBech32(myPubkeyHex, "npub");
    }

    if (myMatch.contains("npub")) {
      pubkeyBech = myMatch;
      final List decode = Helpers().decodeBech32(myMatch);

      myPubkeyHex = decode[0];
    }

    final String pubkeyHr =
        "${pubkeyBech.substring(0, 5)}:${pubkeyBech.substring(pubkeyBech.length - 5)}";

    final myUserMetadata =
        ref.watch(metadataStateProvider(myPubkeyHex)).userMetadata;

    return GestureDetector(
      onTap: () {
        _profileCallback(myPubkeyHex);
      },
      child: Text(
        myUserMetadata != null
            ? "@${myUserMetadata.name ?? pubkeyHr}"
            : "@$pubkeyHr",
        style: const TextStyle(color: Palette.primary, fontSize: 17),
      ),
    );
  }
}
