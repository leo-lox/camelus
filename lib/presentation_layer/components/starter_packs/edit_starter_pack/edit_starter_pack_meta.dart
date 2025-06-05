import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditStarterPackMeta extends ConsumerStatefulWidget {
  const EditStarterPackMeta({super.key});
  @override
  ConsumerState<EditStarterPackMeta> createState() =>
      _EditStarterPackMetaState();
}

class _EditStarterPackMetaState extends ConsumerState<EditStarterPackMeta> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("meta"),
    );
  }
}
