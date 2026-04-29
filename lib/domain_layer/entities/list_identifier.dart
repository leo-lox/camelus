class ListIdentifier {
  final String name;
  final int kind;

  const ListIdentifier({required this.name, required this.kind});

  @override
  bool operator ==(Object other) {
    return other is ListIdentifier && other.name == name && other.kind == kind;
  }

  @override
  int get hashCode => name.hashCode ^ kind.hashCode;
}
