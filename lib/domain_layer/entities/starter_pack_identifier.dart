class StarterPackIdentifier {
  final String pubkey;
  final String name;

  StarterPackIdentifier({
    required this.pubkey,
    required this.name,
  });

  @override
  bool operator ==(Object other) {
    return other is StarterPackIdentifier &&
        other.name == name &&
        other.pubkey == pubkey;
  }

  @override
  int get hashCode => pubkey.hashCode ^ name.hashCode;
}
