import 'package:camelus/helpers/helpers.dart';
import 'package:flutter/material.dart';

class Nip05Text extends StatelessWidget {
  final String pubkey;
  final String? nip05verified;

  String shortHr(String pubkey) {
    final npubHr = Helpers().encodeBech32(pubkey, "npub");

    return "${npubHr.substring(0, 10)}...${npubHr.substring(npubHr.length - 20)}";
  }

  final style = const TextStyle(color: Colors.grey, fontSize: 13);

  const Nip05Text({
    super.key,
    required this.pubkey,
    required this.nip05verified,
  });

  @override
  Widget build(BuildContext context) {
    if (nip05verified == null) {
      return Text(
        shortHr(pubkey),
        style: style,
      );
    } else if (nip05verified!.startsWith("_")) {
      return Text(
        nip05verified!.substring(1),
        style: style,
      );
    } else {
      return Text(
        '@${nip05verified!}',
        style: style,
      );
    }
  }
}
