import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/palette.dart';

class StarterPacksList extends ConsumerWidget {
  final String pubkey;

  const StarterPacksList({
    super.key,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Palette.purple,
      child: Text("test"),
    );
  }
}
