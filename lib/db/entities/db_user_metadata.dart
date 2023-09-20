import 'package:isar/isar.dart';

part 'db_user_metadata.g.dart';

@collection
class DbUserMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true, type: IndexType.value)
  String nostr_id;

  @Index(unique: true, type: IndexType.value)
  String pubkey;

  int last_fetch;

  String? picture;
  String? banner;
  String? name;
  String? nip05;
  String? about;
  String? website;
  String? lud06;
  String? lud16;

  DbUserMetadata({
    required this.pubkey,
    required this.nostr_id,
    required this.last_fetch,
    this.picture,
    this.banner,
    this.name,
    this.nip05,
    this.about,
    this.website,
    this.lud06,
    this.lud16,
  });
}
