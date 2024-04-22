import 'dart:typed_data';

import 'package:camelus/helpers/bip340.dart';

class OnboardingUserInfo {
  String? name = '';
  Uint8List? picture;
  Uint8List? banner;
  String? about = '';
  String? nip05;
  String? website = '';
  bool nip46 = false;
  KeyPair keyPair;

  OnboardingUserInfo({
    this.name,
    this.picture,
    this.banner,
    this.about,
    this.nip05,
    this.website,
    required this.keyPair,
  });
}
