import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain_layer/entities/nostr_list.dart';
import '../../../helpers/helpers.dart';
import '../../../helpers/nprofile_helper.dart';
import '../../atoms/icon_patter.dart';
import '../../atoms/overlapting_avatars.dart';
import '../../providers/metadata_state_provider.dart';

class StarterPackCard extends ConsumerStatefulWidget {
  final NostrStarterPack pack;
  final Function? onTab;
  const StarterPackCard({super.key, required this.pack, this.onTab});

  @override
  ConsumerState<StarterPackCard> createState() => _StarterPackCardState();
}

class _StarterPackCardState extends ConsumerState<StarterPackCard> {
  @override
  Widget build(BuildContext context) {
    final creatorMetadata = ref
        .watch(metadataStateProvider(widget.pack.pubKey))
        .userMetadata;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: widget.onTab != null ? () => widget.onTab!() : null,
      splashColor: widget.onTab != null ? null : Colors.transparent,
      highlightColor: widget.onTab != null ? null : Colors.transparent,
      hoverColor: widget.onTab != null ? null : Colors.transparent,
      focusColor: widget.onTab != null ? null : Colors.transparent,
      child: Card(
        // margin: const EdgeInsets.all(16),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // image
                if (widget.pack.image != null)
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.pack.image!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (widget.pack.image == null) IconPattern(),

                // body - content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 25, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.pack.title ??
                            AppLocalizations.of(context)!.starterPack,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Text(
                        widget.pack.description ?? "",
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

                      // Creator info
                      Row(
                        children: [
                          Text(
                            "by",
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.inverseSurface,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            creatorMetadata?.name ??
                                _pubkeyToHrBech32Short(widget.pack.pubKey),
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.inverseSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          UserImage(
                            size: 20,
                            imageUrl: creatorMetadata?.picture,
                            pubkey: widget.pack.pubKey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // avatars
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
                      avatars: widget.pack.pubKeys.take(5).map((e) {
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
                  // + counter
                  if ((widget.pack.pubKeys.length) > 5)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        "+${(widget.pack.pubKeys.length - 5)}",
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

String _pubkeyToHrBech32Short(String pubkey) {
  final bech = Helpers().encodeBech32(pubkey, "npub");
  final bechShort = NprofileHelper().bech32toHr(bech, cutLength: 11);

  return bechShort;
}
