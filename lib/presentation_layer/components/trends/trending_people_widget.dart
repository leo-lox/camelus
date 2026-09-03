import 'dart:developer';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:apipod_client/apipod_client.dart' as api_pod;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain_layer/entities/contact_list.dart';

import '../../providers/following_contact_state_provider.dart';
import '../../providers/metadata_state_provider.dart';
import '../../providers/trends_provider.dart';
import '../person_card.dart';

class TrendingPeopleWidget extends ConsumerWidget {
  final bool showFollowButton;
  final Function(bool, String) onFollowChange;

  const TrendingPeopleWidget({
    super.key,
    required this.onFollowChange,
    this.showFollowButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.trendingPeople,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _TrendingPeopleList(
            onFollowChange: onFollowChange,
            showFollowButton: showFollowButton,
          ),
        ],
      ),
    );
  }
}

class _TrendingPeopleList extends ConsumerWidget {
  final bool showFollowButton;
  final Function(bool, String) onFollowChange;

  const _TrendingPeopleList({
    required this.onFollowChange,
    required this.showFollowButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactList = ref.watch(contactListSelfStateProvider).contactList;
    final trendsPeopleAsync = ref.watch(trendsPeopleProvider);

    return trendsPeopleAsync.when(
      data: (data) {
        if (!data.success) {
          log(data.error ?? 'trendingPeople endpoint returned success=false');
          return Text(
            AppLocalizations.of(context)!.somethingWentWrong,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }

        if (data.people.isEmpty) {
          return Text(
            AppLocalizations.of(context)!.noConnection,
            style: TextStyle(
              color: Theme.of(context).colorScheme.inverseSurface,
            ),
          );
        }

        return _TrendingPeopleListContent(
          response: data,
          limit: 10,
          contactList: contactList,
          showFollowButton: showFollowButton,
          onFollowChange: onFollowChange,
        );
      },
      error: (error, stackTrace) {
        log(error.toString());
        return Text(
          AppLocalizations.of(context)!.somethingWentWrong,
          style: TextStyle(color: Theme.of(context).colorScheme.inverseSurface),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _TrendingPeopleListContent extends StatelessWidget {
  final api_pod.TrendsResponse response;
  final int limit;
  final ContactList contactList;
  final bool showFollowButton;
  final Function(bool, String) onFollowChange;

  const _TrendingPeopleListContent({
    required this.response,
    required this.limit,
    required this.contactList,
    required this.showFollowButton,
    required this.onFollowChange,
  });

  @override
  Widget build(BuildContext context) {
    final people = response.people.take(limit).toList();

    return Column(
      children: people.map((person) {
        return _TrendingPersonListItem(
          pubkey: person.tag,
          showFollowButton: showFollowButton,
          isFollowing: contactList.contacts.contains(person.tag),
          onFollowChange: onFollowChange,
        );
      }).toList(),
    );
  }
}

class _TrendingPersonListItem extends ConsumerWidget {
  final String pubkey;
  final bool showFollowButton;
  final bool isFollowing;
  final Function(bool, String) onFollowChange;

  const _TrendingPersonListItem({
    required this.pubkey,
    required this.showFollowButton,
    required this.isFollowing,
    required this.onFollowChange,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(metadataStateProvider(pubkey)).userMetadata;

    return PersonCard(
      pubkey: pubkey,
      name: metadata?.name ?? '',
      pictureUrl: metadata?.picture ?? '',
      about: metadata?.about ?? '',
      nip05: metadata?.nip05,
      showFollowButton: showFollowButton,
      isFollowing: isFollowing,
      onTap: () {
        context.push('/profile/$pubkey');
      },
      onFollowTab: (followState) => onFollowChange(followState, pubkey),
    );
  }
}
