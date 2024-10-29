import 'package:objectbox/objectbox.dart';
import 'package:ndk/entities.dart' as ndk_entities;

@Entity()
class DbMetadata {
  @Id()
  int dbId = 0;

  static const int KIND = 0;

  @Property()
  late String pubKey;

  @Property()
  String? name;

  @Property()
  String? displayName;

  @Property()
  String? picture;

  @Property()
  String? banner;

  @Property()
  String? website;

  @Property()
  String? about;

  @Property()
  String? nip05;

  @Property()
  String? lud16;

  @Property()
  String? lud06;

  @Property()
  int? updatedAt;

  @Property()
  int? refreshedTimestamp;

  DbMetadata(
      {this.pubKey = "",
      this.name,
      this.displayName,
      this.picture,
      this.banner,
      this.website,
      this.about,
      this.nip05,
      this.lud16,
      this.lud06,
      this.updatedAt,
      this.refreshedTimestamp});

  String? get cleanNip05 {
    if (nip05 != null) {
      if (nip05!.startsWith("_@")) {
        return nip05!.trim().toLowerCase().replaceAll("_@", "@");
      }
      return nip05!.trim().toLowerCase();
    }
    return null;
  }

  Map<String, dynamic> toFullJson() {
    var data = toJson();
    data['pub_key'] = pubKey;
    return data;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['display_name'] = displayName;
    data['picture'] = picture;
    data['banner'] = banner;
    data['website'] = website;
    data['about'] = about;
    data['nip05'] = nip05;
    data['lud16'] = lud16;
    data['lud06'] = lud06;
    return data;
  }

  bool matchesSearch(String str) {
    str = str.trim().toLowerCase();
    String d = displayName != null ? displayName!.toLowerCase() : "";
    String n = name != null ? name!.toLowerCase() : "";
    String str2 = " $str";
    return d.startsWith(str) ||
        d.contains(str2) ||
        n.startsWith(str) ||
        n.contains(str2);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DbMetadata &&
          runtimeType == other.runtimeType &&
          pubKey == other.pubKey;

  @override
  int get hashCode => pubKey.hashCode;

  ndk_entities.Metadata toNdk() {
    final ndkM = ndk_entities.Metadata(
      pubKey: pubKey,
      name: name,
      displayName: displayName,
      picture: picture,
      banner: banner,
      website: website,
      about: about,
      nip05: nip05,
      lud16: lud16,
      lud06: lud06,
      updatedAt: updatedAt,
      refreshedTimestamp: refreshedTimestamp,
    );

    return ndkM;
  }

  factory DbMetadata.fromNdk(ndk_entities.Metadata ndkM) {
    final dbM = DbMetadata(
      pubKey: ndkM.pubKey,
      name: ndkM.name,
      displayName: ndkM.displayName,
      picture: ndkM.picture,
      banner: ndkM.banner,
      website: ndkM.website,
      about: ndkM.about,
      nip05: ndkM.nip05,
      lud16: ndkM.lud16,
      lud06: ndkM.lud06,
      updatedAt: ndkM.updatedAt,
      refreshedTimestamp: ndkM.refreshedTimestamp,
    );

    return dbM;
  }
}
