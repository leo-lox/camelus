import 'package:camelus/domain_layer/usecases/moderation.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

final moderationProvider = FutureProvider<Moderation>((ref) async {
  final moderation = Moderation();

  return moderation;
});
