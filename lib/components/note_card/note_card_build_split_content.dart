import 'dart:async';
import 'dart:developer';

import 'package:camelus/config/palette.dart';
import 'package:camelus/db/entities/db_user_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/helpers/nprofile_helper.dart';
import 'package:camelus/models/nostr_note.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

final profilePattern = RegExp(r"nostr:(nprofile|npub)[a-zA-Z0-9]+");

/// this class is responsible for building the content of a note
class NoteCardSplitContent {
  final NostrNote _note;

  final Function(String) _profileCallback;
  final Function(String) _hashtagCallback;

  final Map<String, dynamic> _tagsMetadata = {};

  final UserMetadata _metadataProvider;

  List<String> imageLinks = [];

  late Widget _content;

  NoteCardSplitContent(
    this._note,
    this._metadataProvider,
    this._profileCallback,
    this._hashtagCallback,
  ) {
    imageLinks.addAll(_extractImages(_note));
    _content = _buildContentHousing();
  }

  Widget get content => _content;

  _buildContentHousing() {
    return Wrap(
      spacing: 0,
      runSpacing: 4,
      direction: Axis.horizontal,
      verticalDirection: VerticalDirection.down,
      children: _buildContent(_note.content),
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
          widgets.add(_buildProfileLink(word));
        } else if (word.startsWith("#[")) {
          widgets.add(_buildLegacyMentionHashtag(word));
        } else if (word.startsWith("#")) {
          widgets.add(_buildHashtagLink(word));
        } else if (word.startsWith("http")) {
          widgets.add(_buildLink(word));
        } else {
          widgets.add(_buildText(word));
        }
        widgets.add(_buildText(" "));
      }
      widgets.removeLast(); // remove last space
      //widgets.add(_buildText("\n")); // add back the original line break
      widgets.add(const SizedBox(height: 7, width: 1000));
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
          link.endsWith(".gif")) {
        imageLinks.add(link);
      }
    }

    return imageLinks;
  }

  Widget _buildProfileLink(String word) {
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

    var metadata = _metadataProvider.getMetadataByPubkey(myPubkeyHex);

    return GestureDetector(
      onTap: () {
        _profileCallback(myPubkeyHex);
      },
      child: FutureBuilder<DbUserMetadata?>(
          future: metadata,
          builder: (context, metadataSnp) {
            if (metadataSnp.hasData) {
              return Text(
                "@${metadataSnp.data!.name ?? pubkeyHr}",
                style: const TextStyle(color: Palette.primary, fontSize: 17),
              );
            }
            return Text(
              "@$pubkeyHr",
              style: const TextStyle(color: Palette.primary, fontSize: 17),
            );
          }),
    );
  }

  Widget _buildLegacyMentionHashtag(String word) {
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
    var metadata = _metadataProvider.getMetadataByPubkey(tag.value);

    return GestureDetector(
      onTap: () {
        _profileCallback(tag.value);
      },
      child: FutureBuilder<DbUserMetadata?>(
          future: metadata,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Text(
                "@${snapshot.data!.name ?? pubkeyHr}",
                style: const TextStyle(color: Palette.primary, fontSize: 17),
              );
            }
            return Text(
              "@$pubkeyHr",
              style: const TextStyle(color: Palette.primary, fontSize: 17),
            );
          }),
    );
  }

  Widget _buildHashtagLink(String word) {
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

  _buildLink(String word) {
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

  _buildText(String word) {
    return Text(
      word,
      style: const TextStyle(color: Palette.lightGray, fontSize: 17),
    );
  }
}
