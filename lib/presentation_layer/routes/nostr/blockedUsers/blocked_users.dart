import 'dart:async';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.blockedUsers)),
      body: Text(AppLocalizations.of(context)!.notImplemented),
    );
  }
}
