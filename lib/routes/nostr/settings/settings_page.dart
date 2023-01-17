// stateful widget

import 'package:camelus/config/palette.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  late NostrService _nostrService;
  SettingsPage({Key? key}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Palette.background,
      ),
      body: ListView(
        children: [
          // clear cache
          ListTile(
            title: const Text('Clear cache',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              widget._nostrService.clearCache();
            },
          ),
        ],
      ),
    );
  }
}
