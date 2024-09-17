import 'dart:convert';
import 'package:ndk/entities.dart' as ndk_entities;

import '../../domain_layer/entities/user_metadata.dart';

class UserMetadataModel extends UserMetadata {
  UserMetadataModel({
    required super.eventId,
    required super.pubkey,
    required super.lastFetch,
    super.picture,
    super.banner,
    super.name,
    super.nip05,
    super.about,
    super.website,
    super.lud06,
    super.lud16,
  });

  factory UserMetadataModel.fromNDKEvent(ndk_entities.Nip01Event event) {
    final int now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final contentJson = jsonDecode(event.content);

    return UserMetadataModel(
      eventId: event.id,
      pubkey: event.pubKey,
      lastFetch: now,
      picture: contentJson['picture'],
      banner: contentJson['banner'],
      name: contentJson['name'],
      nip05: contentJson['nip05'],
      about: contentJson['about'],
      website: contentJson['website'],
      lud06: contentJson['lud06'],
      lud16: contentJson['lud16'],
    );
  }

  factory UserMetadataModel.fromNDKMetadata(
    ndk_entities.UserMetadata metadata,
  ) {
    return UserMetadataModel(
      eventId: metadata.hashCode.toString(),
      pubkey: metadata.pubKey,
      lastFetch: metadata.refreshedTimestamp ?? 0,
      picture: metadata.picture,
      banner: metadata.banner,
      name: metadata.name,
      nip05: metadata.nip05,
      about: metadata.about,
      website: metadata.website,
      lud06: metadata.lud06,
      lud16: metadata.lud16,
    );
  }
}
