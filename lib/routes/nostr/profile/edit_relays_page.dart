import 'package:camelus/components/edit_relays_view.dart';

import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditRelaysPage extends ConsumerStatefulWidget {
  const EditRelaysPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditRelaysPage> createState() => _EditRelaysPageState();
}

class _EditRelaysPageState extends ConsumerState<EditRelaysPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          title: const Text('Edit Relays'),
          backgroundColor: Palette.background,
        ),
        // show loading indicator when reconnecting
        body: const EditRelaysView(),
      ),
    );
  }
}
