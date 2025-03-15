import '../../domain_layer/repositories/moderation_repository.dart';
import '../data_sources/serverpod_data_source.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final ServerpodDataSource server;

  ModerationRepositoryImpl({
    required this.server,
  });

  @override
  Future<Map<String, dynamic>> fetchBloomFilter() {
    return server.client.moderation.getProfileBloomFilter();
  }
}
