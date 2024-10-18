import '../../../../../domain_layer/entities/contact_list.dart';
import '../../../../../domain_layer/entities/user_metadata.dart';

class GraphNodeData {
  final String pubkey;
  final UserMetadata userMetadata;
  final ContactList contactList;
  bool selected;

  GraphNodeData({
    required this.pubkey,
    required this.userMetadata,
    required this.contactList,
    this.selected = false,
  });

  @override
  String toString() {
    return pubkey;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GraphNodeData && other.pubkey == pubkey;
  }

  @override
  int get hashCode => pubkey.hashCode;
}
