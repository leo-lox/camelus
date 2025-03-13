import 'package:camelus/domain_layer/usecases/moderation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data_layer/repositories/moderation_repository_impl.dart';

final moderationProvider = FutureProvider<Moderation>((ref) async {
  final moderationRepo = ModerationRepositoryImpl();
  final moderation = Moderation(moderationrepository: moderationRepo);

  return moderation;
});
