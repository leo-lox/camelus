import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/user_metadata.dart';
import '../../atoms/my_profile_picture.dart';
import '../../providers/following_contact_state_provider.dart';
import '../../providers/metadata_state_provider.dart';
import 'nostr_side_menu.dart';

class NostrDrawer extends ConsumerWidget {
  final String pubkey;

  //late NostrService _nostrService;

  const NostrDrawer({super.key, required this.pubkey});

  void navigateToProfile(BuildContext context) {
    context.push('/nostr/profile/$pubkey');
  }

  Widget _drawerHeader(context, UserMetadata? metadata, WidgetRef ref) {
    final myContactList = ref.watch(contactListSelfStateProvider);
    return DrawerHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => navigateToProfile(context),
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: UserImage(imageUrl: metadata?.picture, pubkey: pubkey),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => navigateToProfile(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metadata?.name ?? '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          metadata?.nip05 ?? '',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                //Icon(
                //  Icons.arrow_drop_down_rounded,
                //  color: Palette.primary,
                //  size: 30,
                //)
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              RichText(
                text: TextSpan(
                  text: !myContactList.isLoading
                      ? myContactList.contactList.contacts.length.toString()
                      : 'n.a.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: ' Following  ',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              RichText(
                text: TextSpan(
                  text: 'n.a.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  children: [
                    TextSpan(
                      text: 'Followers',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUserMetadata = ref
        .watch(metadataStateProvider(pubkey))
        .userMetadata;
    return Drawer(
      child: NostrSideMenu(
        hideOnMobile: true,
        leadingWidget: _drawerHeader(context, myUserMetadata, ref),
      ),
    );
  }
}
