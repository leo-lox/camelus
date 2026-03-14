import 'dart:developer';
import 'dart:typed_data';

import 'package:ndk/entities.dart' as ndk_entities;
import 'package:ndk/ndk.dart' as ndk;

import '../../domain_layer/entities/user_metadata.dart';
import '../../domain_layer/repositories/metadata_repository.dart';
import '../data_sources/dart_ndk_source.dart';
import '../models/user_metadata_model.dart';

class MetadataRepositoryImpl implements MetadataRepository {
  final DartNdkSource dartNdkSource;
  final ndk.EventVerifier eventVerifier;
  final Duration nip05CacheTtl;

  final Map<String, _Nip05CacheEntry> _nip05CheckCache = {};

  MetadataRepositoryImpl({
    required this.dartNdkSource,
    required this.eventVerifier,
    this.nip05CacheTtl = const Duration(minutes: 10),
  });

  /// nip05 is automatically verified if present and removed if invalid
  @override
  Stream<UserMetadata> getMetadataByPubkey(String pubkey) async* {
    final myMetadata = dartNdkSource.dartNdk.metadata.loadMetadata(pubkey);

    final Stream<ndk_entities.Metadata?> myMetadataStream = myMetadata
        .asStream();

    await for (final event in myMetadataStream) {
      if (event != null) {
        final metadata = UserMetadataModel.fromNDKMetadata(event);

        // Store the original NIP-05 value
        final originalNip05 = metadata.nip05;

        // Set NIP-05 to null for the first event
        metadata.nip05 = null;

        // Emit the first event immediately with NIP-05 set to null
        yield metadata;

        // If there was originally a NIP-05 identifier, perform verification
        if (originalNip05 != null && originalNip05.isNotEmpty) {
          final cacheKey = '$pubkey::$originalNip05';
          final cachedVerification = _getCachedNip05Verification(cacheKey);

          final isValid =
              cachedVerification ??
              (await dartNdkSource.dartNdk.nip05.check(
                nip05: originalNip05,
                pubkey: pubkey,
              )).valid;

          if (cachedVerification == null) {
            _setCachedNip05Verification(cacheKey, isValid);
          }

          // If verification succeeds, set NIP-05 to the original value
          if (isValid) {
            metadata.nip05 = originalNip05;
            // Emit the second event with verified NIP-05
            yield metadata;
          }
          // If verification fails, we don't emit another event
          // as the NIP-05 is already null from the first event
        }
      }
    }
  }

  @override
  Future<UserMetadata> broadcastMetadata(UserMetadata metadata) async {
    final myMetadataModel = UserMetadataModel.fromUserMetadata(metadata);

    final ndkMetadata = myMetadataModel.toNDKMetadata();

    final result = await dartNdkSource.dartNdk.metadata.broadcastMetadata(
      ndkMetadata,
    );
    return UserMetadataModel.fromNDKMetadata(result);
  }

  @override
  Future<Uint8List?> downloadImageUrl(String imageUrl) async {
    try {
      final result = await dartNdkSource.dartNdk.files.download(url: imageUrl);
      return result.data;
    } catch (e) {
      log("image download err $e");
    }

    return null;
  }

  bool? _getCachedNip05Verification(String cacheKey) {
    final entry = _nip05CheckCache[cacheKey];
    if (entry == null) {
      return null;
    }

    final isExpired = DateTime.now().difference(entry.cachedAt) > nip05CacheTtl;
    if (isExpired) {
      _nip05CheckCache.remove(cacheKey);
      return null;
    }

    return entry.valid;
  }

  void _setCachedNip05Verification(String cacheKey, bool isValid) {
    _nip05CheckCache[cacheKey] = _Nip05CacheEntry(
      valid: isValid,
      cachedAt: DateTime.now(),
    );
  }
}

class _Nip05CacheEntry {
  final bool valid;
  final DateTime cachedAt;

  _Nip05CacheEntry({required this.valid, required this.cachedAt});
}
