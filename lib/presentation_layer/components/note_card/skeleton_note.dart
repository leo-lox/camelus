import 'package:camelus/presentation_layer/components/note_card/bottom_action_row.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonNote extends StatelessWidget {
  final Function? renderCallback;
  final bool hideBottomAction;

  const SkeletonNote({
    super.key,
    this.renderCallback,
    this.hideBottomAction = false,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // This code will run after the widget has been rendered
      if (renderCallback != null) {
        renderCallback!();
      }
    });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // profile picture
              Shimmer.fromColors(
                baseColor: Theme.of(context).colorScheme.surface,
                highlightColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                child: Container(
                  height: 60,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // username
                      Shimmer.fromColors(
                        baseColor: Theme.of(context).colorScheme.surface,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Container(
                          height: 18,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Shimmer.fromColors(
                        baseColor: Theme.of(context).colorScheme.surface,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Container(
                          height: 12,
                          width: MediaQuery.of(context).size.width / 2.5,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Shimmer.fromColors(
                        baseColor: Theme.of(context).colorScheme.surface,
                        highlightColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: Container(
                          height: 12,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                      if (!hideBottomAction)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: BottomActionRow(
                            onComment: () {},
                            onLike: () {},
                            onRetweet: () {},
                            onShare: () {},
                            onMore: () {},
                          ),
                        ),
                      const SizedBox(height: 20),
                      // show text if replies > 0
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
