import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WalletMints extends ConsumerWidget {
  const WalletMints({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: null,
      body: ListView(children: <Widget>[Text("WalletMints")]),
    );
  }
}
