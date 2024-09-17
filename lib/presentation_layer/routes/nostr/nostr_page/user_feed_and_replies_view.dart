import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class UserFeedAndRepliesView extends ConsumerStatefulWidget {
  final String pubkey;

  const UserFeedAndRepliesView({super.key, required this.pubkey});

  @override
  UserFeedAndRepliesViewState createState() => UserFeedAndRepliesViewState();
}

class UserFeedAndRepliesViewState
    extends ConsumerState<UserFeedAndRepliesView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text("UserFeedAndRepliesView not implemented");
  }
}
