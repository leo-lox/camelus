enum UserGroup {
  anon,
  member,
  admin;

  static UserGroup fromString(String value) {
    switch (value.toLowerCase()) {
      case 'anon':
        return UserGroup.anon;
      case 'member':
        return UserGroup.member;
      case 'admin':
        return UserGroup.admin;
      default:
        return UserGroup.anon;
    }
  }
}
