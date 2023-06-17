import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

class NoteCardSplitContent {
  final NostrNote _note;

  final Function(String) _profileCallback;

  final Map<String, dynamic> _tagsMetadata = {};

  final NostrService _nostrService;

  List<String> imageLinks = [];

  NoteCardSplitContent(
    this._note,
    this._nostrService,
    this._profileCallback,
  ) {
    imageLinks.addAll(_extractImages(_note));
  }

  List<TextSpan> get textSpans => _buildTextSpans(_note.content);

  List<TextSpan> _buildTextSpans(String content) {
    var spans = _buildUrlSpans(content);
    var completeSpans = _buildHashtagSpans(spans);

    return completeSpans;
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
            }));
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
            var metadata = _nostrService.getUserMetadata(tag.value);

            metadata.then((value) {
              // check if mounted

              _tagsMetadata[tag.value] = value["name"] ?? pubkeyHr;
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
}
