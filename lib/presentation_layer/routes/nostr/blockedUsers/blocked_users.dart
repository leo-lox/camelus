import 'dart:async';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/presentation_layer/atoms/spinner_center.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/metadata_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BlockedUsers extends ConsumerStatefulWidget {
  const BlockedUsers({super.key});

  @override
  ConsumerState<BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<BlockedUsers> {
  Completer initDone = Completer();

  List<NostrTag> contentTags = [];

  @override
  void initState() {
    super.initState();
    _initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initState() async {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: const Text('Blocked Users'),
      ),
      body: const Text('not implemented'),
    );
  }
}
