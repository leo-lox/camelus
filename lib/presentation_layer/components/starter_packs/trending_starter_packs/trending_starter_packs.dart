import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/presentation_layer/components/starter_packs/starter_pack_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain_layer/entities/starter_pack_identifier.dart';
import 'trending_starter_packs_state_provider.dart';

class TrendingStarterPacks extends ConsumerWidget {
  const TrendingStarterPacks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trendingStarterPacksStateProvider);

    if (state.isLoading) {
      return Center(
        child: SpinnerCenter(),
      );
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.starterPacks.length,
        itemBuilder: (context, index) {
          final myPack = state.starterPacks[index];
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.70,
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 8.0 : 0.0,
                right: 4.0,
              ),
              child: StarterPackCard(
                key: ValueKey(myPack.id),
                pack: myPack,
                onTab: () {
                  context.push('/open-starter-pack',
                      extra: StarterPackIdentifier(
                        name: myPack.name,
                        pubkey: myPack.pubKey,
                      ));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
