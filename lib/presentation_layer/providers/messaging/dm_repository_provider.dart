import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/repositories/direct_message_repository.dart';
import 'dm_repository_provider_impl_stub.dart'
    if (dart.library.io) 'dm_repository_provider_impl_io.dart'
    if (dart.library.js_interop) 'dm_repository_provider_impl_web.dart'
    as impl;

final dmRepositoryProvider = Provider<DirectMessageRepository?>((ref) {
  return impl.createDmRepository(ref);
});
