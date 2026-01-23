import 'package:ndk/entities.dart' as ndk_entities;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/camelus_config.dart';
import '../../domain_layer/entities/mem_file.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/entities/nostr_tag.dart';
import '../../helpers/nprofile_helper.dart';
import '../components/write_post/post_settings_dialog.dart';
import 'file_upload_provider.dart';
import 'get_notes_provider.dart';
import 'ndk_provider.dart';

final writePostStateProvider =
    NotifierProvider<WritePostNotifier, WritePostState>(WritePostNotifier.new);

class WritePostState {
  final List<MemFile> images;
  final NostrNote? replyToNote;
  List<String> mentionedInPost;
  List<String> hashtagsInPost;

  final bool isSubmitting;
  final bool isError;
  final String errorText;
  final List<Future<List<ndk_entities.BlobUploadResult>>> uploadTasks;

  final String markupText;

  WritePostState({
    required this.markupText,
    this.isError = false,
    this.errorText = '',
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
    bool clearReplyToNote = false,
    List<String>? mentionedInPost,
    List<String>? hashtagsInPost,
    bool? isSubmitting,
    List<Future<List<ndk_entities.BlobUploadResult>>>? uploadTasks,
    String? markupText,
    bool? isError,
    String? errorText,
  }) {
    return WritePostState(
      images: images ?? this.images,
      replyToNote: clearReplyToNote ? null : (replyToNote ?? this.replyToNote),
      mentionedInPost: mentionedInPost ?? this.mentionedInPost,
      hashtagsInPost: hashtagsInPost ?? this.hashtagsInPost,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      uploadTasks: uploadTasks ?? this.uploadTasks,
      markupText: markupText ?? this.markupText,
      isError: isError ?? this.isError,
      errorText: errorText ?? this.errorText,
    );
  }
}

class WritePostNotifier extends Notifier<WritePostState> {
  addImage(MemFile image) {
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

      var nprofile = NprofileHelper().mapToBech32({
        'pubkey': userHex,
        'relays': [],
      });
      return 'nostr:$nprofile ';
    });

    output = output.replaceAllMapped(RegExp(r'\(__.*?\)'), (match) {
      return '';
    });

    var content = output;

    List<NostrTag> tags = [];

    if (state.replyToNote != null) {
      // handle "e" tags first
      final replyIsReplyToRoot = state.replyToNote!.getRootReply;
      if (replyIsReplyToRoot != null) {
        // reply to a reply - add root "e" tag
        final rootTag = NostrTag(
          type: "e",
          value: replyIsReplyToRoot.value,
          recommendedRelay: "",
          marker: "root",
        );
        tags.add(rootTag);
      } else {
        // direct reply to root - add root "e" tag
        final rootTag = NostrTag(
          type: "e",
          value: state.replyToNote!.id,
          recommendedRelay: "",
          marker: "root",
        );
        tags.add(rootTag);
      }

      // add reply "e" tag (always the note directly replying to)
      final replyTag = NostrTag(
        type: "e",
        value: state.replyToNote!.id,
        recommendedRelay: "",
        marker: "reply",
      );
      tags.add(replyTag);

      // Add previous tweet "e" tags (mentions, not root/reply)
      for (NostrTag tag in state.replyToNote!.tags) {
        if (tag.type == "e") {
          if (tag.marker == "root" || tag.marker == "reply") {
            continue;
          }
          if (!(tags.map((e) => e.value).contains(tag.value))) {
            tags.add(tag);
          }
        }
      }

      // Handle "p" tags - collect all unique pubkeys
      Set<String> pubkeysToTag = {};

      // Add the author of the note we're replying to
      pubkeysToTag.add(state.replyToNote!.pubkey);

      // Add all existing "p" tags from the original note
      for (NostrTag tag in state.replyToNote!.tags) {
        if (tag.type == "p") {
          pubkeysToTag.add(tag.value);
        }
      }

      // Add mentions from the current post
      for (final pubkey in mentionKeys) {
        pubkeysToTag.add(pubkey);
      }

      // Create "p" tags (without markers)

      for (final pubkey in pubkeysToTag) {
        tags.add(
          NostrTag(
            type: "p",
            value: pubkey,
            recommendedRelay:
                "", // todo  await editRelayProvider.getRelayHintsInbox(pubkey);
            // No marker for p tags according to NIP-10
          ),
        );
      }
    } else {
      // Not a reply, but still add mentions as "p" tags
      if (mentionKeys.isNotEmpty) {
        for (int i = 0; i < mentionKeys.length; i++) {
          final pubkey = mentionKeys[i];

          tags.add(
            NostrTag(
              type: "p",
              value: pubkey,
              recommendedRelay:
                  "", //todo  await editRelayProvider.getRelayHintsInbox(pubkey);,
            ),
          );
        }
      }
    }

    // add hashtags
    for (final hashtag in state.hashtagsInPost) {
      tags.add(NostrTag(type: "t", value: hashtag.toLowerCase().substring(1)));
    }

    // upload images
    List<String> imageUrls = [];
    for (final image in state.images) {
      state = state.copyWith(
        uploadTasks: [
          ...state.uploadTasks,
          ref.watch(fileUploadProvider).uploadImage(image).onError((
            err,
            trace,
          ) {
            // display error
            state = state.copyWith(
              isSubmitting: false,
              errorText: "error uploading image: ${err.toString()}",
              isError: true,
            );
            return Future.error(err.toString());
          }),
        ],
      );
    }

    await Future.wait(state.uploadTasks).then((resultList) {
      if (resultList.isEmpty) return;
      imageUrls = resultList
          .where(
            (e) =>
                e.isNotEmpty &&
                e.any((item) => item.descriptor?.url.isNotEmpty == true),
          )
          .map(
            (e) => e
                .firstWhere((item) => item.descriptor?.url.isNotEmpty == true)
                .descriptor!
                .url,
          )
          .toList();
    });

    // add image urls to content
    content += "\n";
    for (var url in imageUrls) {
      content += " $url";
    }

    final notesP = ref.read(getNotesProvider);

    final ndk = ref.read(ndkProvider);
    if (ndk.accounts.cannotSign) {
      state = state.copyWith(isSubmitting: false);
      return Future.error('no signer');
    }
    final pubkey = ndk.accounts.getPublicKey()!;

    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // add post settings tags
    final postSettings = ref.watch(postSettingsProvider);

    if (postSettings.enableContentWarning) {
      tags.add(NostrTag(type: 'content-warning', value: postSettings.warning));
    }
    if (postSettings.enableClientTag) {
      // ["client", "My Client", "31990:app1-pubkey:<d-identifier>", "wss://relay1"]
      tags.add(
        NostrTag(
          type: 'client',
          value: CamelusConfig.name,
          marker: CamelusConfig.identifierAddress,
          recommendedRelay: CamelusConfig.homeRelay,
        ),
      );
    }

    try {
      await notesP.broadcastNote(
        NostrNote(
          id: '',
          pubkey: pubkey,
          createdAt: now,
          kind: 1,
          content: content,
          sig: '',
          tags: tags,
        ),
      );
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        isError: true,
        errorText: e.toString(),
      );
      return Future.error('Error broadcasting note: $e');
    }

    clearPost();
    return;
  }

  void clearPost() {
    ref.read(postSettingsProvider.notifier).reset();
    state = state.copyWith(
      errorText: '',
      isError: false,
      isSubmitting: false,
      uploadTasks: [],
      clearReplyToNote: true,
      markupText: '',
      images: [],
      mentionedInPost: [],
      hashtagsInPost: [],
      replyToNote: null,
    );
  }

  void updateReplyToNote(NostrNote? replyToNote) {
    if (replyToNote == null) {
      state = state.copyWith(clearReplyToNote: true);
      return;
    }
    state = state.copyWith(replyToNote: replyToNote);
  }

  @override
  WritePostState build() {
    return WritePostState(markupText: "");
  }
}
