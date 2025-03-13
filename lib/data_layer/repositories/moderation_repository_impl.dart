import '../../domain_layer/repositories/moderation_repository.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  ModerationRepositoryImpl();

  @override
  Future<Map<String, dynamic>> fetchBloomFilter() {
    throw UnimplementedError();
  }
}
