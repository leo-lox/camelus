import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditStarterPackContent extends ConsumerStatefulWidget {
  const EditStarterPackContent({super.key});
  @override
  ConsumerState<EditStarterPackContent> createState() =>
      _EditStarterPackContentState();
}

class _EditStarterPackContentState
    extends ConsumerState<EditStarterPackContent> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("content"),
    );
  }
}
