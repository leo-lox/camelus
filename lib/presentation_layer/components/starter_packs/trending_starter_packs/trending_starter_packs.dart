import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../atoms/spinner_center.dart';
import '../../../routing/route_paths.dart';
import '../starter_pack_card.dart';
import 'trending_starter_packs_state_provider.dart';

class TrendingStarterPacks extends ConsumerWidget {
  const TrendingStarterPacks({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(trendingStarterPacksStateProvider);

    if (state.isLoading) {
      return Center(child: SpinnerCenter());
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: state.starterPacks.length,
        itemBuilder: (context, index) {
          final myPack = state.starterPacks[index];
          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 300),
            child: Container(
              margin: EdgeInsets.only(left: index == 0 ? 8.0 : 0.0, right: 4.0),
              child: StarterPackCard(
                key: ValueKey(myPack.id),
                pack: myPack,
                onTab: () {
                  context.push(
                    RoutePaths.starterPack(
                      pubkey: myPack.pubKey,
                      name: myPack.name,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
