import '../repositories/moderation_repository.dart';

class Moderation {
  final ModerationRepository _moderationRepository;

  Moderation({
    required ModerationRepository moderationrepository,
  }) : _moderationRepository = moderationrepository;

  Future<void> muteUser(String npub) async {
    throw UnimplementedError();
  }

  Future<void> unmuteUser(String npub) async {
    throw UnimplementedError();
  }

  Future<bool> isMuted(String npub) async {
    throw UnimplementedError();
  }

  /// returns a stream of mutet users by given npub
  Stream<List<String>> getMuted(String npub) {
    throw UnimplementedError();
  }

  ///    'size': <int>,
  ///    'numHashFunctions': <int>,
  ///    'bitArray': <string>,
  Future<Map<String, dynamic>?> fetchBloomFilterProfiles() {
    return _moderationRepository.fetchBloomFilterProfiles();
  }
}
