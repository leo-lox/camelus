import 'dart:convert';

import 'package:camelus/presentation_layer/components/edit_relays_view.dart';
import 'package:camelus/domain_layer/entities/nostr_tag.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:camelus/services/nostr/relays/relay_address_parser.dart';

import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';

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

  Future onSave(Map<String, Map<String, bool>> changedRelays) async {
    Map<String, Map<String, bool>> parsedMap = {};
    // parse all relays
    for (var relay in changedRelays.entries) {
      var parsedKey = RelayAddressParser.parseAddress(relay.key);
      parsedMap[parsedKey] = relay.value;
    }

    var contacts = _saveInContacts(parsedMap);
    var nip65 = _saveNip65(parsedMap);

    await Future.wait([contacts, nip65]);

    return;
  }

  Future _saveInContacts(Map<String, Map<String, bool>> changedRelays) async {
    var followingService = ref.read(followingProvider);

    String myUpdatedContent = jsonEncode(changedRelays);

    await followingService.updateContent(myUpdatedContent);
  }

  Future _saveNip65(Map<String, Map<String, bool>> changedRelays) async {
    //["r", "wss://alicerelay.example.com"],
    //["r", "wss://brando-relay.com"],
    //["r", "wss://expensive-relay.example2.com", "write"],
    //["r", "wss://nostr-relay.example.com", "read"],

    var newNip65Tags = List<NostrTag>.empty(growable: true);

    for (var relay in changedRelays.entries) {
      if (relay.value['read'] == true && relay.value['write'] == true) {
        newNip65Tags.add(NostrTag(
          type: 'r',
          value: relay.key,
        ));
      } else if (relay.value['read'] == true) {
        newNip65Tags.add(NostrTag(
          type: 'r',
          value: relay.key,
          recommended_relay: 'read',
        ));
      } else if (relay.value['write'] == true) {
        newNip65Tags.add(NostrTag(
          type: 'w',
          value: relay.key,
          recommended_relay: 'write',
        ));
      }
    }
    var followingService = ref.read(followingProvider);
    await followingService.publishNip65(newNip65Tags);

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
