import 'dart:convert';

import 'package:camelus/domain_layer/entities/relay.dart';
import 'package:camelus/presentation_layer/components/edit_relays_view.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';

import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditRelaysPage extends ConsumerStatefulWidget {
  const EditRelaysPage({super.key});

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

  Future onSave(List<Relay> changedRelays) async {
    throw UnimplementedError("save in nip65");

    return;
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
          foregroundColor: Palette.lightGray,
        ),
        // show loading indicator when reconnecting
        body: EditRelaysView(
          onSave: onSave,
        ),
      ),
    );
  }
}
