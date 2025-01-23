import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain_layer/entities/mem_file.dart';

final writePostStateProvider =
    NotifierProvider<WritePostNotifier, WritePostState>(
  WritePostNotifier.new,
);

class WritePostState {
  final List<MemFile> images;
  final String? replyToPubkey;
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
    this.replyToPubkey,
    this.mentionedInPost = const [],
    this.hashtagsInPost = const [],
  });

  copyWith({
    List<MemFile>? images,
    String? replyToPostId,
    List<String>? mentionedInPost,
    List<String>? hashtagsInPost,
    bool? isSubmitting,
    List<Future<String>>? uploadTasks,
    String? markupText,
  }) {
    return WritePostState(
      images: images ?? this.images,
      replyToPubkey: replyToPostId ?? this.replyToPubkey,
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

  submitPost() {}

  @override
  WritePostState build() {
    return WritePostState(markupText: "");
  }
}
