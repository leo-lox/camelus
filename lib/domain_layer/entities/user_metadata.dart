class UserMetadata {
  String eventId;

  String pubkey;

  int lastFetch;

  String? picture;
  String? banner;
  String? name;
  String? nip05;
  String? about;
  String? website;
  String? lud06;
  String? lud16;

  UserMetadata({
    required this.eventId,
    required this.pubkey,
    required this.lastFetch,
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
