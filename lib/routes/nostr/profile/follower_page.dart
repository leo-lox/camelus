import 'package:camelus/atoms/follow_button.dart';
import 'package:camelus/atoms/person_card.dart';
import 'package:camelus/models/nostr_tag.dart';
import 'package:camelus/providers/metadata_provider.dart';
import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:camelus/services/nostr/metadata/user_metadata.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/helpers/helpers.dart';
import 'package:camelus/routes/nostr/profile/profile_page.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FollowerPage extends ConsumerStatefulWidget {
  String title;
  List<NostrTag> contacts;

  FollowerPage({
    Key? key,
    required this.title,
    required this.contacts,
  }) : super(key: key) {}

  @override
  ConsumerState<FollowerPage> createState() => _FollowerPageState();
}

class _FollowerPageState extends ConsumerState<FollowerPage> {
  late NostrService _nostrService;
  List<String> _myFollowing = [];
  final List<String> _myNewFollowing = [];
  final List<String> _myNewUnfollowing = [];

  void getFollowed() {
    List<List> folloing =
        _nostrService.following[_nostrService.myKeys.publicKey] ?? [];
    for (var i = 0; i < folloing.length; i++) {
      _myFollowing.add(folloing[i][1]);
    }

    setState(() {
      _myFollowing = _myFollowing;
    });
  }

  _calculateFollowing() {
    for (var i = 0; i < _myNewFollowing.length; i++) {
      if (!_myFollowing.contains(_myNewFollowing[i])) {
        _myFollowing.add(_myNewFollowing[i]);
      }
    }

    for (var i = 0; i < _myNewUnfollowing.length; i++) {
      if (_myFollowing.contains(_myNewUnfollowing[i])) {
        _myFollowing.remove(_myNewUnfollowing[i]);
      }
    }
    if (_myNewFollowing.isNotEmpty || _myNewUnfollowing.isNotEmpty) {
      // write event to nostr

      var tags = [];

      for (var i = 0; i < _myFollowing.length; i++) {
        var d = ["p", _myFollowing[i]];
        tags.add(d);
      }

      _nostrService.writeEvent("", 3, tags);

      // update following locally
      _nostrService.following[_nostrService.myKeys.publicKey] = [];
      for (var i = 0; i < _myFollowing.length; i++) {
        var d = ["p", _myFollowing[i]];
        _nostrService.following[_nostrService.myKeys.publicKey]!.add(d);
      }
    }
    // get updated contacts
    _nostrService.getUserContacts(_nostrService.myKeys.publicKey);
  }

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    _initNostrService();
    getFollowed();
  }

  @override
  void dispose() {
    _calculateFollowing();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var metadata = ref.watch(metadataProvider);
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        backgroundColor: Palette.background,
        title: Text(widget.title),
      ),
      body: ListView.builder(
          itemCount: widget.contacts.length,
          itemBuilder: (context, index) {
            return FutureBuilder<Map<dynamic, dynamic>>(
                future:
                    metadata.getMetadataByPubkey(widget.contacts[index].value),
                builder: (BuildContext context, snapshot) {
                  return PersonCard(
                    pubkey: widget.contacts[index].value,
                    name: snapshot.data?["name"] ?? "",
                    pictureUrl: snapshot.data?["picture"] ?? "",
                    about: snapshot.data?["about"] ?? "",
                    nip05: snapshot.data?["nip05"] ?? "",
                    isFollowing: true,
                  );
                });
          }),
    );
  }
}
