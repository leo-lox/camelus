import 'package:ndk/shared/nips/nip19/nip19.dart';

class RoutePaths {
  static String profileIdentifier({required String pubkey, String? nip05}) {
    final normalizedNip05 = nip05?.trim();
    if (normalizedNip05 != null &&
        normalizedNip05.isNotEmpty &&
        normalizedNip05.contains('@')) {
      return Uri.encodeComponent(normalizedNip05);
    }

    return Nip19.encodePubKey(pubkey);
  }

  static String profile({required String pubkey, String? nip05}) {
    final identifier = profileIdentifier(pubkey: pubkey, nip05: nip05);
    return '/profile/$identifier';
  }

  static String profileEdit({required String pubkey, String? nip05}) {
    return '${profile(pubkey: pubkey, nip05: nip05)}/edit';
  }

  static String status({
    required String pubkey,
    required String eventId,
    String? nip05,
    String? scrollIntoView,
  }) {
    return statusByIdentifier(
      profileIdentifier: profileIdentifier(pubkey: pubkey, nip05: nip05),
      eventId: eventId,
      scrollIntoView: scrollIntoView,
    );
  }

  static String statusByIdentifier({
    required String profileIdentifier,
    required String eventId,
    String? scrollIntoView,
  }) {
    final identifier = Uri.encodeComponent(
      Uri.decodeComponent(profileIdentifier),
    );

    final basePath = '/profile/$identifier/status/$eventId';
    if (scrollIntoView == null || scrollIntoView.isEmpty) {
      return basePath;
    }

    final encodedScrollIntoView = Uri.encodeQueryComponent(scrollIntoView);
    return '$basePath?scrollIntoView=$encodedScrollIntoView';
  }

  static String listEdit({
    required int kind,
    required String name,
    bool isNew = false,
    String? defaultTitle,
    bool isPrivate = false,
  }) {
    final base = '/lists/$kind/${Uri.encodeComponent(name)}/edit';
    final params = <String, String>{
      if (isNew) 'new': 'true',
      if (defaultTitle != null && defaultTitle.isNotEmpty)
        'defaultTitle': Uri.encodeQueryComponent(defaultTitle),
      if (isPrivate) 'private': 'true',
    };
    if (params.isEmpty) return base;
    return '$base?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
  }

  static String starterPack({required String pubkey, required String name}) {
    return '/starter/${Nip19.encodePubKey(pubkey)}/${Uri.encodeComponent(name)}';
  }

  static String starterPackEdit({
    required String pubkey,
    required String name,
    bool isNew = false,
  }) {
    final base =
        '/starter/${Nip19.encodePubKey(pubkey)}/${Uri.encodeComponent(name)}/edit';
    return isNew ? '$base?new=true' : base;
  }

  static String map() => '/map';

  static String mapNavigation() => '${map()}/navigation';
}
