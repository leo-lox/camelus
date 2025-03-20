import 'package:camelus/presentation_layer/providers/ndk_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data_layer/repositories/moderation_repository_impl.dart';
import '../../../domain_layer/usecases/moderation.dart';
import '../get_notes_provider.dart';
import '../serverpod_provider.dart';

final moderationProvider = Provider<Moderation>((ref) {
  final serverpodDs = ref.watch(serverpodProvider);
  final moderationRepo = ModerationRepositoryImpl(server: serverpodDs);
  final getNotes = ref.watch(getNotesProvider);
  final ndk = ref.watch(ndkProvider);
  final moderation = Moderation(
    moderationrepository: moderationRepo,
    notes: getNotes,
    ndk: ndk,
  );

  return moderation;
});
