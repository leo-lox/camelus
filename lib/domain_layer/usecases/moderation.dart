class Moderation {
  Future<void> muteUser(String npub) async {
    throw UnimplementedError();
  }

  Future<void> unmuteUser(String npub) async {
    throw UnimplementedError();
  }

  Future<bool> isMuted(String npub) async {
    throw UnimplementedError();
  }

  /// returns a stream of mutet users by given npub
  Stream<List<String>> getMuted(String npub) {
    throw UnimplementedError();
  }
}
