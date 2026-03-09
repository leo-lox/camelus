import 'dart:convert';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

import '../../../data_layer/models/nostr_note_model.dart';
import '../../../domain_layer/entities/nostr_note.dart';
import '../../../helpers/helpers.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/ndk_provider.dart';
import '../../providers/parsed_note_cache_provider.dart';
import '../../routing/route_paths.dart';
import 'note_card_container.dart';
import 'skeleton_note.dart';

final _repostedNoteProvider = Provider.family<NostrNote?, String>((
  ref,
  content,
) {
  try {
    final noteModel = NostrNoteModel.fromJson(jsonDecode(content));
    ref.read(ndkProvider).config.cache.saveEvent(noteModel.toNDKEvent());

    return noteModel;
  } catch (_) {
    return null;
  }
});

class NoteCardRepost extends ConsumerWidget {
  final NostrNote repostEvent;

  const NoteCardRepost({super.key, required this.repostEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repostedNote = ref.watch(_repostedNoteProvider(repostEvent.content));

    return Column(
      children: [
        _RepostHeader(repostEvent: repostEvent),
        if (repostedNote == null)
          Text(
            'Failed to parse reposted note',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          )
        else
          _RepostedNoteBody(note: repostedNote),
      ],
    );
  }
}

class _RepostHeader extends ConsumerWidget {
  final NostrNote repostEvent;

  const _RepostHeader({required this.repostEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(
      metadataStateProvider(
        repostEvent.pubkey,
      ).select((s) => s.userMetadata?.name),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/retweet.svg',
            height: 18,
            colorFilter: const ColorFilter.mode(
              Color.fromARGB(255, 22, 163, 74),
              BlendMode.srcATop,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  context.push(RoutePaths.profile(pubkey: repostEvent.pubkey)),
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.inverseSurface,
                  ),
                  children: [
                    TextSpan(
                      text: name ?? Helpers().shortHr(repostEvent.pubkey),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    TextSpan(
                      text: AppLocalizations.of(context)!.shared,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepostedNoteBody extends ConsumerWidget {
  final NostrNote note;

  const _RepostedNoteBody({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsedAsync = ref.watch(parsedNoteCacheProvider(note));

    return parsedAsync.when(
      data: (parsed) => parsed == null
          ? const SizedBox.shrink()
          : NoteCardContainer(key: PageStorageKey(parsed.id), note: parsed),
      loading: () => const SkeletonNote(hideBottomAction: true),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
