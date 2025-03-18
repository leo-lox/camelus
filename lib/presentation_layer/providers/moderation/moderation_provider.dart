import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data_layer/repositories/moderation_repository_impl.dart';
import '../../../domain_layer/usecases/moderation.dart';
import '../get_notes_provider.dart';
import '../serverpod_provider.dart';

final moderationProvider = FutureProvider<Moderation>((ref) async {
  final serverpodDs = ref.watch(serverpodProvider);
  final moderationRepo = ModerationRepositoryImpl(server: serverpodDs);
  final getNotes = ref.watch(getNotesProvider);
  final moderation = Moderation(
    moderationrepository: moderationRepo,
    notes: getNotes,
  );

  return moderation;
});
