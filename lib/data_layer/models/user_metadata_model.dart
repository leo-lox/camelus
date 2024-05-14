import 'dart:convert';

import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:dart_ndk/nips/nip01/event.dart';

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

  factory UserMetadataModel.fromNDKEvent(Nip01Event event) {
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
}
