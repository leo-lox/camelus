class VoiceChannel {
  final String id;
  final String name;
  final String? parentId;
  final int position;
  final List<String> userIds;

  VoiceChannel({
    required this.id,
    required this.name,
    this.parentId,
    required this.position,
    this.userIds = const [],
  });

  VoiceChannel copyWith({
    String? id,
    String? name,
    String? parentId,
    int? position,
    List<String>? userIds,
  }) {
    return VoiceChannel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      position: position ?? this.position,
      userIds: userIds ?? this.userIds,
    );
  }
}
