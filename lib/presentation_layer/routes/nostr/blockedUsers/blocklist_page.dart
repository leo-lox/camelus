import 'dart:async';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlocklistPage extends ConsumerStatefulWidget {
  const BlocklistPage({super.key});

  @override
  ConsumerState<BlocklistPage> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends ConsumerState<BlocklistPage> {
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
