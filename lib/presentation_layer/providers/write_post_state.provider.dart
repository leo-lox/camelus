import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/mem_file.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/nostr_tag.dart';
import '../../helpers/nprofile_helper.dart';
import 'edit_relays_provider.dart';
import 'event_signer_provider.dart';
import 'file_upload_provider.dart';
import 'get_notes_provider.dart';

final writePostStateProvider =
    NotifierProvider<WritePostNotifier, WritePostState>(
  WritePostNotifier.new,
);

class WritePostState {
  final List<MemFile> images;
  final NostrNote? replyToNote;
  List<String> mentionedInPost;
  List<String> hashtagsInPost;

  final bool isSubmitting;
  final List<Future<String>> uploadTasks;

  final String markupText;

  WritePostState({
    required this.markupText,
    this.isSubmitting = false,
    this.uploadTasks = const [],
    this.images = const [],
    this.replyToNote,
    this.mentionedInPost = const [],
    this.hashtagsInPost = const [],
  });

  copyWith({
    List<MemFile>? images,
    NostrNote? replyToNote,
    List<String>? mentionedInPost,
    List<String>? hashtagsInPost,
    bool? isSubmitting,
    List<Future<String>>? uploadTasks,
    String? markupText,
  }) {
    return WritePostState(
      images: images ?? this.images,
      replyToNote: replyToNote ?? this.replyToNote,
      mentionedInPost: mentionedInPost ?? this.mentionedInPost,
      hashtagsInPost: hashtagsInPost ?? this.hashtagsInPost,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadTasks: uploadTasks ?? this.uploadTasks,
      markupText: markupText ?? this.markupText,
    );
  }
}

class WritePostNotifier extends Notifier<WritePostState> {
  addImage(
    MemFile image,
  ) {
    state = state.copyWith(images: [...state.images, image]);
  }

  updateMarkup(String markupText) {
    state = state.copyWith(markupText: markupText);
    extractMentions();
    extractHashtags();
  }

  extractMentions() {
    final mentionKeys = <String>[];
    final keyRegex = RegExp(r'@\[__(.*?)__\]');

    state.markupText.replaceAllMapped(keyRegex, (match) {
      mentionKeys.add(match.group(1)!);
      return '';
    });

    state.mentionedInPost = mentionKeys;
  }

  extractHashtags() {
    final hashtagKeys = <String>[];
    final keyRegex = RegExp(r'#\w+');

    state.markupText.replaceAllMapped(keyRegex, (match) {
      hashtagKeys.add(match.group(0)!);
      return '';
    });

    state.hashtagsInPost = hashtagKeys;
  }

  Future submitPost() async {
    if (state.isSubmitting) return;
    if (state.markupText.isEmpty) return;

    state = state.copyWith(isSubmitting: true);

    // extract mentions from markupText
    extractMentions();
    extractHashtags();

    final mentionKeys = <String>[];
    final keyRegex = RegExp(r'@\[__(.*?)__\]');

    String output = state.markupText.replaceAllMapped(keyRegex, (match) {
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

    if (state.replyToNote != null) {
      final replyIsReplyToRoot = state.replyToNote!.getRootReply;
      if (replyIsReplyToRoot != null) {
        final tag = NostrTag(
          type: "e",
          value: replyIsReplyToRoot.value,
          recommended_relay: "",
          marker: "root",
        );
        tags.add(tag);
      } else {
        // is reply to root
        final tag = NostrTag(
          type: "e",
          value: state.replyToNote!.id,
          recommended_relay: "",
          marker: "root",
        );
        tags.add(tag);
        final tagPubkey = NostrTag(
          type: "p",
          value: state.replyToNote!.pubkey,
          recommended_relay: "",
          marker: "root",
        );
        tags.add(tagPubkey);
      }

      // add previous tweet tags
      for (NostrTag tag in state.replyToNote!.tags) {
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
          final pubkey = mentionKeys[i];
          final editRelayProvider = ref.watch(editRelaysProvider);

          final potentialRelays =
              await editRelayProvider.getRelayHintsInbox(pubkey);

          tags.add(NostrTag(
            type: "p",
            value: pubkey,
            recommended_relay: potentialRelays.firstOrNull?.url ?? "",
            marker: "mention",
          ));
        }
      }

      if (state.replyToNote != null) {
        final tag = NostrTag(
          type: "e",
          value: state.replyToNote!.id,
          recommended_relay: "",
          marker: "reply",
        );
        tags.add(tag);

        final tagPubkey = NostrTag(
          type: 'p',
          value: state.replyToNote!.pubkey,
          recommended_relay: '',
          marker: 'reply',
        );
        tags.add(tagPubkey);
      }
    }

    // add hashtags
    for (final hashtag in state.hashtagsInPost) {
      tags.add(
        NostrTag(
          type: "t",
          value: hashtag.toLowerCase().substring(1),
        ),
      );
    }

    // upload images
    List<String> imageUrls = [];
    for (final image in state.images) {
      state.uploadTasks.add(ref.watch(fileUploadProvider).uploadImage(image));
    }

    //todo!: err handling
    await Future.wait(state.uploadTasks).then((urls) {
      imageUrls = urls;
    });

    // add image urls to content
    content += "\n";
    for (var url in imageUrls) {
      content += " $url";
    }

    final notesP = ref.read(getNotesProvider);

    final signerP = ref.read(eventSignerProvider);
    if (signerP == null) {
      state = state.copyWith(isSubmitting: false);
      return Future.error('no signer');
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
        state = state.copyWith(isSubmitting: false);
        return Future.error('Error broadcasting note: $error');
      },
    );
  }

  @override
  WritePostState build() {
    return WritePostState(markupText: "");
  }
}
