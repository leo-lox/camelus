import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/repositories/moderation_repository.dart';
import '../data_sources/serverpod_data_source.dart';
import '../models/nostr_note_model.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final ServerpodDataSource server;

  ModerationRepositoryImpl({
    required this.server,
  });

  @override
  Future<Map<String, dynamic>?> fetchBloomFilterProfiles() {
    return server.client.moderation.getProfileBloomFilter();
  }

  @override
  Future<String> reportToCamelus(NostrNote report) {
    final NostrNoteModel model = NostrNoteModel.fromEntity(report);
    final ndkEvent = model.toNDKEvent();
    return server.client.moderation.report(ndkEvent);
  }
}
