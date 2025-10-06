import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/palette.dart';
import '../../../domain_layer/entities/nostr_band_hashtags.dart';
import '../../atoms/hashtag_card.dart';
import '../../providers/nostr_band_provider.dart';

class TrendingHashtagsWidget extends ConsumerWidget {
  const TrendingHashtagsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nostrBandAsync = ref.watch(
      nostrBandProvider.select(
        (provider) => provider.getTrendingHashtags(),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "trending hashtags",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          FutureBuilder<NostrBandHashtags?>(
            future: nostrBandAsync,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                log(snapshot.error.toString());
                return Text(
                  'Something went wrong',
                  style: TextStyle(color: Paletter.getGray(context)),
                );
              }

              if (snapshot.hasData && snapshot.data != null) {
                return _buildHashtagsList(context, snapshot.data!, 10);
              }

              if (snapshot.connectionState == ConnectionState.done) {
                return Text(
                  'No connection',
                  style: TextStyle(color: Paletter.getGray(context)),
                );
              }

              return Column(
                children: List.generate(
                  10,
                  (i) => const HashtagCardSkeleton(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHashtagsList(
      BuildContext context, NostrBandHashtags api, int limit) {
    final hashtags = api.hashtags;
    final displayLimit = limit > hashtags.length ? hashtags.length : limit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        displayLimit,
        (i) {
          final hashtag = hashtags[i];
          return HashtagCard(
            index: i,
            hashtag: hashtag.hashtag,
            postsCount: hashtag.posts,
            onTap: (hashtag) {
              context.push('/nostr/search', extra: "#$hashtag");
            },
          );
        },
      ),
    );
  }
}
