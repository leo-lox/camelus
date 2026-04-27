import 'package:flutter/material.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import '../../../components/lists/edit_list/edit_list.dart';

class EditListPage extends StatelessWidget {
  final ListIdentifier identifier;
  final bool isNewList;

  const EditListPage({
    super.key,
    required this.identifier,
    required this.isNewList,
  });

  @override
  Widget build(BuildContext context) {
    return EditList(listIdentifier: identifier, isNewList: isNewList);
  }
}
