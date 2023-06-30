import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// this class is responsible for building the content of a note
class NoteCardSplitContent {
  final NostrNote _note;

  final Function(String) _profileCallback;

  final Function _stateCallback;

  final Map<String, dynamic> _tagsMetadata = {};

  final UserMetadata _metadataProvider;

  List<String> imageLinks = [];

  NoteCardSplitContent(
    this._note,
    this._metadataProvider,
    this._profileCallback,
    this._stateCallback,
  ) {
    imageLinks.addAll(_extractImages(_note));
  }

  List<TextSpan> get _textSpans => _buildTextSpans(_note.content);

  Widget get content => _buildContent();

  Widget _buildContent() {
    return FutureBuilder(
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return RichText(
              text: TextSpan(
                children: _textSpans,
              ),
            );
          } else {
            return RichText(
              text: TextSpan(
                children: _textSpans,
              ),
            );
          }
        },
        future: _metadataProvider.getMetadataByPubkey(_note.pubkey));
  }

  List<TextSpan> _buildTextSpans(String content) {
    var urlSpans = _buildUrlSpans(content);
    var hashtagSpans = _buildHashtagSpans(urlSpans);
    var nprofileSpans = _buildNprofileSpans(hashtagSpans);

    return nprofileSpans;
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
          link.endsWith(".gif")) {
        imageLinks.add(link);
      }
    }

    return imageLinks;
  }

  /// removes the given strings from the input
  String _removeStrings(String input, List<String> strings) {
    for (var string in strings) {
      input = input.replaceAll(string, "");
    }
    return input;
  }

  List<TextSpan> _buildUrlSpans(String input) {
    // remove image links from input
    input = _removeStrings(input, imageLinks);

    final spans = <TextSpan>[];
    final linkRegex = RegExp(
        r"(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]");
    final linkMatches = linkRegex.allMatches(input);
    int lastMatchEnd = 0;
    for (final match in linkMatches) {
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: input.substring(lastMatchEnd, match.start),
            style: const TextStyle(
                color: Palette.lightGray, fontSize: 17, height: 1.3),
          ),
        );
      }
      spans.add(TextSpan(
        text: match.group(0),
        style: const TextStyle(
            color: Palette.primary,
            fontSize: 17,
            height: 1.3,
            decoration: TextDecoration.underline),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (match.group(0) == null) return;

            // Open the URL in a browser
            launchUrlString(match.group(0)!,
                mode: LaunchMode.externalApplication);
            log(match.group(0)!);
          },
      ));
      lastMatchEnd = match.end;
    }
    if (lastMatchEnd < input.length) {
      spans.add(TextSpan(
          text: input.substring(lastMatchEnd),
          style: const TextStyle(
              color: Palette.lightGray, fontSize: 17, height: 1.3)));
    }
    return spans;
  }

  List<TextSpan> _buildHashtagSpans(List<TextSpan> spans) {
    var finalSpans = <TextSpan>[];

    for (var span in spans) {
      if (span.text!.contains("#[")) {
        final pattern = RegExp(r"#\[\d+\]");
        final hashMatches = pattern.allMatches(span.text!);
        int lastMatchEnd = 0;
        for (final match in hashMatches) {
          if (match.start > lastMatchEnd) {
            finalSpans.add(
              TextSpan(
                text: span.text!.substring(lastMatchEnd, match.start),
                style: const TextStyle(
                    color: Palette.lightGray, fontSize: 17, height: 1.3),
              ),
            );
          }
          var indexString =
              match.group(0)!.replaceAll("#[", "").replaceAll("]", "");
          var index = int.parse(indexString);
          var tag = _note.tags[index];

          if (tag.type == 'p' && _tagsMetadata[tag.value] == null) {
            var pubkeyBech = Helpers().encodeBech32(tag.value, "npub");
            // first 5 chars then ... then last 5 chars
            var pubkeyHr =
                "${pubkeyBech.substring(0, 5)}...${pubkeyBech.substring(pubkeyBech.length - 5)}";
            _tagsMetadata[tag.value] = pubkeyHr;
            var metadata = _metadataProvider.getMetadataByPubkey(tag.value);

            metadata.then((value) {
              // check if mounted

              _tagsMetadata[tag.value] = value["name"] ?? pubkeyHr;
              _stateCallback();
            });
          }
          finalSpans.add(TextSpan(
              text: "@${_tagsMetadata[tag.value]}",
              style: const TextStyle(
                  color: Palette.primary, fontSize: 17, height: 1.3),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _profileCallback(tag.value);
                }));
          lastMatchEnd = match.end;
        }
        if (lastMatchEnd < span.text!.length) {
          finalSpans.add(
            TextSpan(
              text: span.text!.substring(lastMatchEnd),
              style: const TextStyle(
                  color: Palette.lightGray, fontSize: 17, height: 1.3),
            ),
          );
        }
      } else {
        finalSpans.add(span);
      }
    }

    return finalSpans;
  }

  List<TextSpan> _buildNprofileSpans(List<TextSpan> spans) {
    final finalSpans = <TextSpan>[];

    for (final span in spans) {
      // only edit my spans and not the ones that are already edited
      if (!span.text!.contains("nostr:nprofile") &&
          !span.text!.contains("nostr:npub")) {
        finalSpans.add(span);
        continue;
      }

      final pattern = RegExp(r"nostr:(nprofile|npub)[a-zA-Z0-9]+");
      final hashMatches = pattern.allMatches(span.text!);
      var lastMatchEnd = 0;

      for (final match in hashMatches) {
        if (match.start > lastMatchEnd) {
          finalSpans.add(TextSpan(
            text: span.text!.substring(lastMatchEnd, match.start),
            style: const TextStyle(
              color: Palette.lightGray,
              fontSize: 17,
              height: 1.3,
            ),
          ));
        }

        final myMatch = match.group(0)!.replaceAll("nostr:", "");
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
          final List decode = Helpers().decodeBech32(myMatch);
          myPubkeyHex = decode[0];
          pubkeyBech = myMatch;
        }

        final String pubkeyHr =
            "${pubkeyBech.substring(0, 5)}...${pubkeyBech.substring(pubkeyBech.length - 5)}";

        var metadata = _metadataProvider.getMetadataByPubkey(myPubkeyHex);

        if (_tagsMetadata[myPubkeyHex] == null) {
          _tagsMetadata[myPubkeyHex] = pubkeyHr;

          metadata.then((value) {
            _tagsMetadata[myPubkeyHex] = value["name"];
          });
        }

        finalSpans.add(TextSpan(
          text: "@${_tagsMetadata[myPubkeyHex]}",
          style: const TextStyle(
            color: Palette.primary,
            fontSize: 17,
            height: 1.3,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (match.group(0) == null) return;
              // log(match.group(0)!);
              _profileCallback(myPubkeyHex);
            },
        ));

        lastMatchEnd = match.end;
      }

      if (lastMatchEnd < span.text!.length) {
        finalSpans.add(TextSpan(
          text: span.text!.substring(lastMatchEnd),
          style: const TextStyle(
            color: Palette.lightGray,
            fontSize: 17,
            height: 1.3,
          ),
        ));
      }
    }

    return finalSpans;
  }
}
