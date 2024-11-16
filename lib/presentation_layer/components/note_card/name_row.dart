import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/user_metadata.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/presentation_layer/atoms/nip_05_text.dart';
import 'package:camelus/presentation_layer/providers/nip05_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

class NoteCardNameRow extends ConsumerStatefulWidget {
  final UserMetadata? myMetadata;
  final String pubkey;
  final int createdAt;

  const NoteCardNameRow({
    super.key,
    required this.myMetadata,
    required this.pubkey,
    required this.createdAt,
  });

  @override
  ConsumerState<NoteCardNameRow> createState() => _NoteCardNameRowState();
}

class _NoteCardNameRowState extends ConsumerState<NoteCardNameRow> {
  late String npubHrShort;
  late String dateText;

  @override
  void initState() {
    super.initState();
    _initSequence();

    final now = DateTime.now();
    final postDateTime =
        DateTime.fromMillisecondsSinceEpoch(widget.createdAt * 1000);
    final difference = now.difference(postDateTime);

    if (difference.inDays < 2) {
      // Use timeago for posts less than 2 days old
      dateText = timeago.format(postDateTime);
    } else {
      // Use a human-readable date format for posts 2 days or older
      dateText = DateFormat('MMM d, yyyy').format(postDateTime);
    }
  }

  void _initSequence() {
    var npubHr = Helpers().encodeBech32(widget.pubkey, "npub");
    npubHrShort =
        "${npubHr.substring(0, 4)}...${npubHr.substring(npubHr.length - 4)}";
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Nip05Text(
                pubkey: widget.pubkey,
                nip05verified: widget.myMetadata?.nip05,
              ),
            ],
          ),
        ),
        Text(
          dateText,
          style: const TextStyle(color: Palette.gray, fontSize: 14),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}
