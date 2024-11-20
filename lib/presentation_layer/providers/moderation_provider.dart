import 'package:camelus/domain_layer/usecases/moderation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final moderationProvider = FutureProvider<Moderation>((ref) async {
  final moderation = Moderation();

  return moderation;
});
