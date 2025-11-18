import 'package:apipod_client/apipod_client.dart' as sp;

import '../../domain_layer/entities/bloom_filter_data.dart';
import '../../domain_layer/entities/nostr_note.dart';
import '../../domain_layer/repositories/moderation_repository.dart';
import '../data_sources/serverpod_data_source.dart';
import '../models/bloom_filter_data_model.dart';
import '../models/nostr_note_model.dart';

class ModerationRepositoryImpl implements ModerationRepository {
  final ServerpodDataSource server;

  ModerationRepositoryImpl({required this.server});

  @override
  Future<BloomFilterData?> fetchBloomFilterProfiles() async {
    final sp.BloomFilterData? data = await server.client.moderation
        .getProfileBloomFilter();
    if (data == null) {
      return null;
    }

    return BloomFilterDataModel.fromServerpod(data);
  }

  @override
  Future<BloomFilterData?> fetchBloomFilterEvents() async {
    final sp.BloomFilterData? data = await server.client.moderation
        .getEventBloomFilter();
    if (data == null) {
      return null;
    }

    return BloomFilterDataModel.fromServerpod(data);
  }

  @override
  Future<String> reportToCamelus(NostrNote report) {
    final NostrNoteModel model = NostrNoteModel.fromEntity(report);
    final ndkEvent = model.toNDKEvent();
    return server.client.moderation.report(ndkEvent);
  }
}
