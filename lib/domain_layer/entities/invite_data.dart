class InviteData {
  final String inviteByNpub;
  final String listName;
  final String? listNpub;

  InviteData({
    required this.inviteByNpub,
    required this.listName,
    this.listNpub,
  });

  InviteData.empty() : inviteByNpub = "", listName = "", listNpub = null;

  bool get isEmpty => inviteByNpub.isEmpty && listName.isEmpty;
}
