import 'package:flutter/widgets.dart';

import '../trends/trending_hashtags_widget.dart';
import '../trends/trending_people_widget.dart';

class RightSiedbar extends StatelessWidget {
  const RightSiedbar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 50, left: 10, right: 10),
        child: ListView(
          children: [
            TrendingHashtagsWidget(),
            const SizedBox(height: 20),
            TrendingPeopleWidget(
              onFollowChange: (change, pubkey) {
                throw UnimplementedError();
              },
              showFollowButton: false,
            )
          ],
        ),
      ),
    );
  }
}
