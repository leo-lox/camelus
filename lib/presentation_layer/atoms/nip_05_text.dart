import 'package:camelus/helpers/helpers.dart';
import 'package:flutter/material.dart';

class Nip05Text extends StatelessWidget {
  final String pubkey;
  final String? nip05verified;
  final TextStyle? customStyle;
  final bool cutPubkey;

  String shortHr(String pubkey) {
    final npubHr = Helpers().encodeBech32(pubkey, "npub");
    if (!cutPubkey) {
      return npubHr;
    }

    return "${npubHr.substring(0, 8)}...${npubHr.substring(npubHr.length - 10)}";
  }

  const Nip05Text({
    super.key,
    required this.pubkey,
    required this.nip05verified,
    this.customStyle,
    this.cutPubkey = true,
  });

  @override
  Widget build(BuildContext context) {
    final style =
        customStyle ?? const TextStyle(color: Colors.grey, fontSize: 13);

    if (nip05verified == null) {
      return Text(
        "@${shortHr(pubkey)}",
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else if (nip05verified!.startsWith("_")) {
      return Text(
        nip05verified!.substring(1),
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    } else {
      return Text(
        '@${nip05verified!}',
        style: style,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
  }
}
