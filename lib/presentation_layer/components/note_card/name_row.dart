import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/presentation_layer/providers/nip05_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

class NoteCardNameRow extends ConsumerStatefulWidget {
  final UserMetadata? myMetadata;
  final String pubkey;
  final int createdAt;
  final VoidCallback openMore;

  const NoteCardNameRow({
    super.key,
    required this.myMetadata,
    required this.pubkey,
    required this.createdAt,
    required this.openMore,
  });

  @override
  ConsumerState<NoteCardNameRow> createState() => _NoteCardNameRowState();
}

class _NoteCardNameRowState extends ConsumerState<NoteCardNameRow> {
  String nip05verified = "";
  late String npubHrShort;

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  void _initSequence() {
    var npubHr = Helpers().encodeBech32(widget.pubkey, "npub");
    npubHrShort =
        "${npubHr.substring(0, 4)}...${npubHr.substring(npubHr.length - 4)}";
    _checkNip05(widget.myMetadata?.nip05 ?? "", widget.pubkey);
  }

  void _checkNip05(String nip05, String pubkey) async {
    if (nip05.isEmpty || nip05verified.isNotEmpty) return;
    try {
      final nip05Service = await ref.read(nip05provider.future);
      final check = await nip05Service.check(nip05, pubkey);
      if (check != null && check.valid) {
        setState(() {
          nip05verified = check.nip05;
        });
      }
    } catch (e) {
      // Handle or log the error if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: widget.myMetadata?.name ?? npubHrShort,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      const TextSpan(text: '  '),
                      const TextSpan(text: ' · '),
                      TextSpan(
                        text: timeago.format(
                            DateTime.fromMillisecondsSinceEpoch(
                                widget.createdAt * 1000)),
                        style:
                            const TextStyle(color: Palette.gray, fontSize: 14),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (nip05verified.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(left: 5),
                  child: Icon(
                    Icons.verified,
                    color: Palette.white,
                    size: 15,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _MoreButton(onTap: widget.openMore),
      ],
    );
  }
}

class _MoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7.5),
          child: SvgPicture.asset(
            'assets/icons/tweetSetting.svg',
            height: 25,
            colorFilter: const ColorFilter.mode(
              Palette.darkGray,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
