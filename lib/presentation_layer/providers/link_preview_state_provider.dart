import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_riverpod/legacy.dart';

final linkPreviewProvider = StateProvider.family<PreviewData?, String>(
  (ref, link) => null,
);
