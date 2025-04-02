import 'dart:ui';

import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/presentation_layer/components/images_tile_view.dart';
import 'package:camelus/presentation_layer/components/note_card/note_card_reference.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/domain_layer/entities/nostr_note.dart';
import 'package:camelus/presentation_layer/providers/metadata_state_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';

final profilePattern = RegExp(r"nostr:(nprofile|npub)[a-zA-Z0-9]+");
final notePattern = RegExp(r"nostr:(note|nevent)[a-zA-Z0-9]+");

/// this class is responsible for building the content of a note

class NoteCardSplitContent extends ConsumerStatefulWidget {
  final NostrNote note;
  final Function(String) profileCallback;
  final Function(String) hashtagCallback;
  final double _fontSize;

  const NoteCardSplitContent({
    super.key,
    required this.note,
    required this.hashtagCallback,
    required this.profileCallback,
    required final double fontSize,
  }) : _fontSize = fontSize;

  @override
  ConsumerState<NoteCardSplitContent> createState() =>
      _NoteCardSplitContentState();
}

class _NoteCardSplitContentState extends ConsumerState<NoteCardSplitContent> {
  late List<InlineSpan> _contentSpans;
  late List<String> _imageLinks;
  late Set<String> _profileHexIdentifiers;
  final Map<String, WidgetSpan> _memoizedNoteReferences = {};
  bool _isContentRevealed = false;

  bool _isExpanded = false;
  final double _collapsedHeight = 250.0;
  bool _shouldShowButton = false;

  @override
  void initState() {
    super.initState();
    _parseContent();

    // Check if content needs "Show More" button after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkIfContentExceedsHeight();
    });
  }

  @override
  void didUpdateWidget(NoteCardSplitContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.note.id != widget.note.id) {
      _parseContent();
      _isExpanded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _checkIfContentExceedsHeight();
      });
    }
  }

  void _checkIfContentExceedsHeight() {
    // Calculate the total content height
    final textHeight = _calculateTextHeight(widget.note.content);
    final imageHeight = _imageLinks.isEmpty ? 0 : 200; // Image height + spacing
    final totalHeight = textHeight + imageHeight;

    // If content exceeds collapsed height, show the button; + image height so post with images get more space
    if (totalHeight > _collapsedHeight + imageHeight) {
      setState(() {
        _shouldShowButton = true;
      });
    }
  }

  double _calculateTextHeight(String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Palette.lightGray, fontSize: widget._fontSize),
      ),
      maxLines: null,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: MediaQuery.of(context).size.width - 60);

    return textPainter.height;
  }

  void _parseContent() {
    _imageLinks = _extractImages(widget.note);
    _profileHexIdentifiers = _extractProfileHexIdentifiers(widget.note.content);
    //_contentSpans = _buildContentSpans(widget.note.content, null);
  }

  @override
  Widget build(BuildContext context) {
    final hasContentWarning = widget.note.contentWarning != null;
    // Watch metadata for all profile links
    final metadataMap = Map.fromEntries(
      _profileHexIdentifiers.map((hexId) => MapEntry(
            hexId,
            ref.watch(metadataStateProvider(hexId)).userMetadata,
          )),
    );

    return Stack(
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          enabled: hasContentWarning && !_isContentRevealed,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Constrained content container
              ConstrainedBox(
                constraints: BoxConstraints(
                  // Only apply max height when not expanded AND content needs to be constrained
                  maxHeight: (!_isExpanded && _shouldShowButton)
                      ? _collapsedHeight
                      : double.infinity,
                ),
                child: ClipRect(
                  // Only clip when not expanded and should show button

                  clipBehavior: (!_isExpanded && _shouldShowButton)
                      ? Clip.hardEdge
                      : Clip.none,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: _buildContentSpans(
                            widget.note.content,
                            metadataMap,
                          ),
                        ),
                        style: TextStyle(
                          color: Palette.lightGray,
                          fontSize: widget._fontSize,
                          height: 1.2,
                          wordSpacing: 1.05,
                        ),
                        maxLines: _isExpanded
                            ? null
                            : null, // Let it flow naturally within constraint
                        overflow: TextOverflow.clip,
                      ),
                      if (_imageLinks.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        ImagesTileView(images: _imageLinks),
                      ],
                    ],
                  ),
                ),
              ),

              // Show More button if needed
              if (_shouldShowButton) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      decoration: BoxDecoration(
                        color: Palette.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isExpanded ? "Show Less" : "Show More",
                        style: const TextStyle(
                          color: Palette.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (hasContentWarning && !_isContentRevealed)
          Center(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.warningOctagon(),
                        color: Palette.error,
                        size: 32,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.note.contentWarning!,
                        style: const TextStyle(
                          color: Palette.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isContentRevealed = true;
                      });
                    },
                    child: longButton(
                        name: "show",
                        onPressed: () {
                          setState(() {
                            _isContentRevealed = true;
                          });
                        }),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Set<String> _extractProfileHexIdentifiers(String content) {
    final profileRegex = RegExp(r'nostr:(nprofile|npub)[a-zA-Z0-9]+');
    return profileRegex
        .allMatches(content)
        .map((match) => _extractHexFromProfileLink(
            match.group(0)!.replaceAll('nostr:', '')))
        .toSet();
  }

  List<InlineSpan> _buildContentSpans(
      String content, Map<String, UserMetadata?>? metadataMap) {
    List<InlineSpan> spans = [];
    RegExp exp = RegExp(
      r'nostr:(nprofile|npub)[a-zA-Z0-9]+|'
      r'nostr:(note|nevent)[a-zA-Z0-9]+|'
      r'(#\$\$\s*[0-9]+\s*\$\$)|'
      r'(#\w+)|' // Hashtags
      r'(https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*))', // URLs
      caseSensitive: false,
    );

    content.splitMapJoin(
      exp,
      onMatch: (Match match) {
        String? matched = match.group(0);
        if (matched != null) {
          if (matched.startsWith('nostr:')) {
            spans.add(_buildProfileOrNoteSpan(matched, metadataMap));
          } else if (matched.startsWith('#[')) {
            spans.add(_buildLegacyMentionSpan(matched));
          } else if (matched.startsWith('#')) {
            spans.add(_buildHashtagSpan(matched));
          } else if (matched.startsWith('http')) {
            spans.add(_buildUrlSpan(matched));
          }
        }
        return '';
      },
      onNonMatch: (String text) {
        spans.add(TextSpan(
          text: text,
        ));
        return '';
      },
    );

    return spans;
  }

  InlineSpan _buildProfileOrNoteSpan(
      String word, Map<String, UserMetadata?>? metadataMap) {
    final cleanedWord = word.replaceAll('nostr:', '');
    final isProfile =
        cleanedWord.startsWith('nprofile') || cleanedWord.startsWith('npub');
    final isNote =
        cleanedWord.startsWith('note') || cleanedWord.startsWith('nevent');

    if (isProfile) {
      final hexIdentifier = _extractHexFromProfileLink(cleanedWord);
      final displayText = _getProfileDisplayText(hexIdentifier);
      return TextSpan(
        text: displayText,
        style: const TextStyle(color: Palette.primary),
        recognizer: TapGestureRecognizer()
          ..onTap = () => widget.profileCallback(hexIdentifier),
      );
    } else if (isNote) {
      return _memoizedNoteReferences.putIfAbsent(
        word,
        () => WidgetSpan(
          child: NoteCardReference(key: ValueKey(word), word: word),
          alignment: PlaceholderAlignment.middle,
        ),
      );
    } else {
      return TextSpan(text: word);
    }
  }

  String _extractHexFromProfileLink(String link) {
    if (link.startsWith('nprofile')) {
      final decoded = NprofileHelper().bech32toMap(link);
      return decoded['pubkey'] ?? '';
    } else if (link.startsWith('npub')) {
      final decoded = Helpers().decodeBech32(link);
      return decoded[0] ?? '';
    }
    return '';
  }

  String _getProfileDisplayText(String hexIdentifier) {
    final metadata =
        ref.read(metadataStateProvider(hexIdentifier)).userMetadata;
    if (metadata?.name != null && metadata!.name!.isNotEmpty) {
      return '@${metadata.name}';
    } else {
      final npub = Helpers().encodeBech32(hexIdentifier, 'npub');
      return '@${npub.substring(0, 5)}...${npub.substring(npub.length - 5)}';
    }
  }

  InlineSpan _buildLegacyMentionSpan(String word) {
    // Implement logic for legacy mentions
    return TextSpan(
      text: word,
      style: const TextStyle(color: Palette.primary),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          // Handle legacy mention tap
        },
    );
  }

  InlineSpan _buildHashtagSpan(String word) {
    return TextSpan(
      text: word,
      style: const TextStyle(color: Palette.primary),
      recognizer: TapGestureRecognizer()
        ..onTap = () => widget.hashtagCallback(word),
    );
  }

  InlineSpan _buildUrlSpan(String url) {
    if (_imageLinks.contains(url)) {
      return const TextSpan(text: '');
    }
    return TextSpan(
      text: url,
      style: const TextStyle(color: Palette.primary),
      recognizer: TapGestureRecognizer()
        ..onTap =
            () => launchUrlString(url, mode: LaunchMode.externalApplication),
    );
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
    required this.fontSize,
  });

  final String word;

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      word,
      style: TextStyle(color: Palette.lightGray, fontSize: fontSize),
    );
  }
}

class HttpLink extends StatelessWidget {
  const HttpLink(
      {super.key,
      required this.imageLinks,
      required this.word,
      required this.fontSize});

  final List<String> imageLinks;
  final String word;
  final double fontSize;

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
        style: TextStyle(color: Palette.primary, fontSize: fontSize),
      ),
    );
  }
}

class HashtagLink extends StatelessWidget {
  const HashtagLink(
      {super.key,
      required Function(String p1) hashtagCallback,
      required this.word,
      required this.fontSize})
      : _hashtagCallback = hashtagCallback;

  final Function(String p1) _hashtagCallback;
  final String word;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    String hashtag = word.substring(1);

    return GestureDetector(
      onTap: () {
        _hashtagCallback(hashtag);
      },
      child: Text(
        word,
        style: TextStyle(color: Palette.primary, fontSize: fontSize),
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
    required this.fontSize,
  }) : _profileCallback = profileCallback;

  final Function(String p1) _profileCallback;
  final String word;
  final double fontSize;

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
        style: TextStyle(color: Palette.primary, fontSize: fontSize),
      ),
    );
  }
}
