import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/palette.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return Scaffold(
        backgroundColor: Palette.background,
        body: const Center(
          child:
              Text('work in progress', style: TextStyle(color: Colors.white)),
        ));
  }
}
