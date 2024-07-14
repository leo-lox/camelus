import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/presentation_layer/providers/nip05_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class NoteCardNameRow extends ConsumerStatefulWidget {
  final UserMetadata? myMetadata;
  final String pubkey;
  final int created_at;
  final Function openMore;

  const NoteCardNameRow(
      {super.key,
      required this.myMetadata,
      required this.pubkey,
      required this.created_at,
      required this.openMore});

  @override
  ConsumerState<NoteCardNameRow> createState() => _NoteCardNameRowState();
}

class _NoteCardNameRowState extends ConsumerState<NoteCardNameRow> {
  String nip05verified = "";
  String npubHrShort = "";

  void _checkNip05(String nip05, String pubkey) async {
    if (nip05.isEmpty) return;
    if (nip05verified.isNotEmpty) return;
    try {
      var nip05Service = await ref.watch(nip05provider.future);
      var check = await nip05Service.check(nip05, pubkey);

      if (check != null && check.valid) {
        setState(() {
          nip05verified = check.nip05;
        });
      }
      // ignore: empty_catches
    } catch (e) {}
  }

  void _initSqeuence() async {
    var npubHr = Helpers().encodeBech32(widget.pubkey, "npub");
    npubHrShort =
        "${npubHr.substring(0, 4)}...${npubHr.substring(npubHr.length - 4)}";
  }

  @override
  void initState() {
    super.initState();
    _initSqeuence();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
        //mainAxisAlignment: MainAxisAlignment.end,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 5, maxWidth: 150),
                child: RichText(
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    text: widget.myMetadata?.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                ),
              ),
              if (nip05verified.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 0, left: 5),
                  child: const Icon(
                    Icons.verified,
                    color: Palette.white,
                    size: 15,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Container(
            height: 3,
            width: 3,
            decoration: const BoxDecoration(
              color: Palette.gray,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              timeago.format(DateTime.fromMillisecondsSinceEpoch(
                  widget.created_at * 1000)),
              style: const TextStyle(color: Palette.gray, fontSize: 12),
            ),
          ),
          GestureDetector(
            onTap: () {
              widget.openMore();
            },
            child: SvgPicture.asset(
              'assets/icons/tweetSetting.svg',
              color: Palette.darkGray,
            ),
          )
        ]);
  }
}
