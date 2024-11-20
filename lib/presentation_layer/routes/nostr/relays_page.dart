import 'package:camelus/config/palette.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RelaysPage extends ConsumerStatefulWidget {
  const RelaysPage({super.key});

  @override
  ConsumerState<RelaysPage> createState() => _RelaysPageState();
}

class _RelaysPageState extends ConsumerState<RelaysPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: SafeArea(
        child: Text("disabled"),
      ),
    );
  }
}
