
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class GlobalFeedView extends ConsumerStatefulWidget {
  const GlobalFeedView({Key? key}) : super(key: key);

  @override
  ConsumerState<GlobalFeedView> createState() => _GlobalFeedViewState();
}

class _GlobalFeedViewState extends ConsumerState<GlobalFeedView> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text("testing ground"),
    );
  }
}
