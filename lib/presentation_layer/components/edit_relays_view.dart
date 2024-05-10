import 'dart:developer';
import 'package:camelus/presentation_layer/atoms/long_button.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/presentation_layer/providers/following_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EditRelaysView extends ConsumerStatefulWidget {
  // async function with Map<String, Map<String, bool>> as parameter
  final Function(Map<String, Map<String, bool>>) onSave;
  const EditRelaysView({super.key, required this.onSave});

  @override
  ConsumerState<EditRelaysView> createState() => _EditRelaysViewState();
}

class _EditRelaysViewState extends ConsumerState<EditRelaysView> {
  final TextEditingController _relayNameController = TextEditingController();

  bool reconnecting = false;
  bool touched = false;
  bool loading = false;

  late Map<String, Map<String, bool>> myRelays = {};

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

    relayName = RelayAddressParser.parseAddress(relayName);

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

  _saveRelays() async {
    log("saving relays $myRelays");
    setState(() {
      loading = true;
    });
    // write to relays
    await widget.onSave(myRelays);
    setState(() {
      loading = false;
      touched = false;
    });
  }

  void _initSequence() async {
    var followingPubkeys = ref.read(followingProvider);
    await followingPubkeys.servicesReady;
    var relays = followingPubkeys.ownRelays;
    Map<String, Map<String, bool>> relaysMap = {};

    for (var relay in relays.entries) {
      // cast to Map<String, bool>
      relaysMap[relay.key] = relay.value.cast<String, bool>();
    }
    setState(() {
      myRelays = Map.from(relaysMap);
    });
    return;
  }

  @override
  void initState() {
    super.initState();
    _initSequence();
  }

  @override
  void dispose() {
    _relayNameController.dispose();
    super.dispose();
  }

  _checkClose() async {
    if (!touched) {
      Navigator.of(context).pop();
      return;
    }
    // show dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Discard changes?"),
          content: const Text("Do you want to discard your changes?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Discard"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _checkClose();
        return false;
      },
      child: reconnecting
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
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20),
                  child: TextField(
                    controller: _relayNameController,
                    decoration: const InputDecoration(
                      hintText: " add relay",
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Palette.lightGray),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Palette.white),
                        borderRadius: BorderRadius.all(Radius.circular(30)),
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (value) {
                      _addRelay();
                    },
                  ),
                ),
                const SizedBox(height: 20),
                for (var relay in myRelays.entries)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 10,
                      right: 10,
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      //round corners
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Palette.extraDarkGray,
                      ),
                      height: 85,
                      width: double.infinity,

                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          Text(
                            relay.key,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const Spacer(),
                          // switch button read
                          Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Checkbox(
                                activeColor: Palette.lightGray,
                                checkColor: Palette.black,
                                value: relay.value["read"] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    touched = true;
                                    if (relay.value["read"] != null) {
                                      relay.value["read"] =
                                          !relay.value["read"]!;
                                    } else {
                                      relay.value["read"] = true;
                                    }
                                  });
                                },

                                //activeColor: Palette.primary,
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
                              Checkbox(
                                activeColor: Palette.lightGray,
                                checkColor: Palette.black,
                                value: relay.value["write"] ?? false,
                                onChanged: (value) {
                                  setState(() {
                                    touched = true;
                                    if (relay.value["write"] != null) {
                                      relay.value["write"] =
                                          !relay.value["write"]!;
                                    } else {
                                      relay.value["write"] = true;
                                    }
                                  });
                                },
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
                  ),
                const SizedBox(height: 10),
                Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 10),
                  child: longButton(
                    name: "save",
                    onPressed: _saveRelays,
                    inverted: true,
                    disabled: !touched,
                    loading: loading,
                  ),
                ),
              ],
            ),
    );
  }
}
