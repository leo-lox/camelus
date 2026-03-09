import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LinkPreviewNotifier extends Notifier<PreviewData?> {
  final String link;
  LinkPreviewNotifier(this.link);

  @override
  PreviewData? build() => null;

  void setPreview(PreviewData? preview) {
    state = preview;
  }
}

final linkPreviewProvider =
    NotifierProvider.family<LinkPreviewNotifier, PreviewData?, String>(
      LinkPreviewNotifier.new,
    );
