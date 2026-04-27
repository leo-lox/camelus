import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/nostr_list.dart';
import '../../atoms/icon_patter.dart';
import '../../atoms/overlapting_avatars.dart';
import '../../providers/metadata_state_provider.dart';

class ListCard extends ConsumerWidget {
  final NostrSet list;
  final VoidCallback? onTap;

  const ListCard({super.key, required this.list, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      splashColor: onTap != null ? null : Colors.transparent,
      highlightColor: onTap != null ? null : Colors.transparent,
      hoverColor: onTap != null ? null : Colors.transparent,
      focusColor: onTap != null ? null : Colors.transparent,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner image or fallback pattern
                if (list.image != null)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(list.image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  const IconPattern(),

                // Content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Kind badge
                      _KindBadge(kind: list.kind),
                      const SizedBox(height: 6),
                      // Title
                      Text(
                        list.title ?? AppLocalizations.of(context)!.lists,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (list.description != null &&
                          list.description!.isNotEmpty)
                        Text(
                          list.description!,
                          maxLines: 3,
                          textAlign: TextAlign.justify,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: Theme.of(context).colorScheme.inverseSurface,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Item count for curation sets
                      if (list.kind == NostrList.curationSet)
                        Text(
                          '${list.threads.length} notes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.inverseSurface,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Overlapping avatars for follow sets
            if (list.kind == NostrList.followSet && list.pubKeys.isNotEmpty)
              Positioned(
                top: 100,
                left: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 155,
                      child: OverlappingAvatars(
                        avatarSize: 40,
                        avatars: list.pubKeys.take(5).map((e) {
                          return UserImage(
                            imageUrl: ref
                                .watch(metadataStateProvider(e.value))
                                .userMetadata
                                ?.picture,
                            pubkey: e.value,
                          );
                        }).toList(),
                      ),
                    ),
                    if (list.pubKeys.length > 5)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          '+${list.pubKeys.length - 5}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.inverseSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _KindBadge extends StatelessWidget {
  final int kind;
  const _KindBadge({required this.kind});

  @override
  Widget build(BuildContext context) {
    final isFollow = kind == NostrList.followSet;
    final label = isFollow
        ? AppLocalizations.of(context)!.followSetKind
        : AppLocalizations.of(context)!.curationSetKind;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
