class ListIdentifier {
  final String name;
  final int kind;

  /// Optional pre-filled title shown when creating a new list.
  /// Not included in equality/hashCode so it doesn't affect provider identity.
  final String? defaultTitle;

  /// Whether the list's elements should be encrypted (NIP-51 private content).
  /// Not included in equality/hashCode so it doesn't affect provider identity.
  final bool isPrivate;

  const ListIdentifier({
    required this.name,
    required this.kind,
    this.defaultTitle,
    this.isPrivate = false,
  });

  @override
  bool operator ==(Object other) {
    return other is ListIdentifier && other.name == name && other.kind == kind;
  }

  @override
  int get hashCode => name.hashCode ^ kind.hashCode;
}
