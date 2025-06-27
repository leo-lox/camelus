import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletReceive extends ConsumerWidget {
  const WalletReceive({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: null,
      body: ListView(children: <Widget>[Text("WalletReceive")]),
    );
  }
}
