import 'key_pair.dart';
import 'mem_file.dart';

class OnboardingUserInfo {
  String? name = '';
  MemFile? picture;
  MemFile? banner;
  String? about = '';
  String? pronouns = '';
  String? nip05;
  String? website = '';
  bool nip46 = false;
  KeyPair keyPair;
  List<String> followPubkeys = [];
  String lud06 = '';
  String lud16 = '';

  // if invited by someone
  String? invitedByPubkey = '';
  String? inviteListName = '';

  OnboardingUserInfo({
    this.name,
    this.picture,
    this.banner,
    this.about,
    this.pronouns,
    this.nip05,
    this.website,
    this.nip46 = false,
    this.lud06 = '',
    this.lud16 = '',
    required this.keyPair,
    this.invitedByPubkey,
    this.inviteListName,
  });
}
