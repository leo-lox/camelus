import 'dart:convert';
import 'dart:developer';

import 'package:camelus/providers/nostr_service_provider.dart';
import 'package:flutter/material.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/services/nostr/nostr_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditRelaysPage extends ConsumerStatefulWidget {
  EditRelaysPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EditRelaysPage> createState() => _EditRelaysPageState();
}

class _EditRelaysPageState extends ConsumerState<EditRelaysPage> {
  late NostrService _nostrService;
  // copy of relays from nostr service
  late var myRelays = _nostrService.relays.manualRelays;

  final TextEditingController _relayNameController = TextEditingController();

  bool reconnecting = false;
  bool touched = false;

  void _addRelay() {
    setState(() {
      touched = true;
    });
    String relayName = _relayNameController.text;
    if (relayName.isEmpty) {
      return;
    }

    // check if relay begins with wss://
    if (!relayName.startsWith("wss://")) {
      // add wss:// to relay name
      relayName = "wss://$relayName";
      log("added");
    }

    // check if relay already exists
    if (myRelays.containsKey(relayName)) {
      // show dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Relay already exists"),
            content: const Text("A relay with this name already exists."),
            actions: [
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    setState(() {
      myRelays[relayName] =
          // ignore: unnecessary_cast
          {"read": true, "write": true} as Map<String, bool>;
    });

    _relayNameController.clear();
  }

  // get called when going back
  _closeView() async {
    if (touched == false) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      reconnecting = true;
    });
    await _saveRelays();
    setState(() {
      reconnecting = false;
    });

    // ignore: use_build_context_synchronously
    Navigator.of(context).pop();
  }

  _saveRelays() async {
    _nostrService.relays.setManualRelays(myRelays);
    // publish relays to nostr service

    String relaysJson = jsonEncode(myRelays);
    log(relaysJson);
    var following = _nostrService.following[_nostrService.myKeys.publicKey];

    // add to cache

    // todo write event
    await _nostrService.writeEvent(relaysJson, 3, following as List);

    await _reconnect();
  }

  Future<void> _reconnect() async {
    await _nostrService.relays.closeRelays();
    await _nostrService.relays.connectToRelays();
    return;
  }

  void _initNostrService() {
    _nostrService = ref.read(nostrServiceProvider);
  }

  @override
  void initState() {
    super.initState();
    _initNostrService();
  }

  @override
  void dispose() {
    _relayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _closeView();
        return false;
      },
      child: Scaffold(
        backgroundColor: Palette.background,
        appBar: AppBar(
          title: const Text('Edit Relays'),
          backgroundColor: Palette.background,
        ),
        // show loading indicator when reconnecting
        body: reconnecting
            ? const Center(
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    "reconnecting to relays...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ))
            : ListView(
                children: [
                  for (var relay in myRelays.entries)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      //round corners
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Palette.extraDarkGray,
                      ),
                      height: 100,
                      width: double.infinity,

                      child: Row(
                        children: [
                          Text(
                            relay.key,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          // switch button read
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Switch(
                                thumbColor:
                                    MaterialStateProperty.all(Palette.primary),
                                value: relay.value["read"],
                                onChanged: (value) {
                                  setState(() {
                                    touched = true;
                                    relay.value["read"] = !relay.value["read"];
                                  });
                                },
                                activeTrackColor: Palette.darkGray,
                                activeColor: Palette.primary,
                              ),
                              const Text(
                                'read',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          // switch button write
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Switch(
                                thumbColor:
                                    MaterialStateProperty.all(Palette.primary),
                                value: relay.value["write"],
                                onChanged: (value) {
                                  setState(() {
                                    touched = true;
                                    relay.value["write"] =
                                        !relay.value["write"];
                                  });
                                },
                                activeTrackColor: Palette.darkGray,
                                activeColor: Palette.primary,
                              ),
                              const Text(
                                'write',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          // delete button
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Palette.lightGray,
                                ),
                                onPressed: () {
                                  // confirm dialog
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Delete relay"),
                                        content: const Text(
                                            "Are you sure you want to delete this relay?"),
                                        actions: [
                                          TextButton(
                                            child: const Text("Cancel"),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: const Text("Delete"),
                                            onPressed: () {
                                              setState(() {
                                                touched = true;
                                                myRelays.remove(relay.key);
                                              });
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              const Text(
                                'delete',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _relayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Relay name',
                      labelStyle: TextStyle(color: Palette.lightGray),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Palette.lightGray),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Palette.primary),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  // add relay button
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: () {
                        _addRelay();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add relay'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
