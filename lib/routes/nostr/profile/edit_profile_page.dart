import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/services/nostr/nostr_injector.dart';
import 'package:camelus/services/nostr/nostr_service.dart';

class EditProfilePage extends StatefulWidget {
  late NostrService _nostrService;

  EditProfilePage({Key? key}) : super(key: key) {
    NostrServiceInjector injector = NostrServiceInjector();
    _nostrService = injector.nostrService;
  }

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // create text input controllers
  TextEditingController pictureController = TextEditingController(text: "");
  TextEditingController bannerController = TextEditingController(text: "");
  TextEditingController nameController = TextEditingController(text: "");
  TextEditingController nip05Controller = TextEditingController(text: "");
  TextEditingController aboutController = TextEditingController(text: "");
  TextEditingController websiteController = TextEditingController(text: "");

  // scroll controller
  final ScrollController _scrollController = ScrollController();

  late String pubkey;

  bool loading = true;

  bool isKeysExpanded = false;

  @override
  void initState() {
    super.initState();
    // get user public key
    pubkey = widget._nostrService.myKeys.publicKey;

    // set initial values of text input controllers
    _loadProfileValues();
    // listen to changes in text input controllers
    pictureController.addListener(() {
      setState(() {});
    });
    bannerController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // dispose text input controllers
    pictureController.dispose();
    bannerController.dispose();
    nameController.dispose();
    nip05Controller.dispose();
    aboutController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  void copyToClipboard(String data) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
      ),
    );
    await Clipboard.setData(ClipboardData(text: data));
    // show snackbar
  }

  Future<void> _loadProfileValues() async {
    var profileData = await widget._nostrService.getUserMetadata(pubkey);
    setState(() {
      loading = false;
    });
    log(profileData.toString());

    if (profileData["notFound"] == true) {
      return;
    }

    // set initial values of text input controllers
    pictureController.text = profileData["picture"] ?? "";
    bannerController.text = profileData["banner"] ?? "";
    nameController.text = profileData["name"] ?? "";
    nip05Controller.text = profileData["nip05"] ?? "";
    aboutController.text = profileData["about"] ?? "";
    websiteController.text = profileData["website"] ?? "";
  }

  void _submitData() {
    setState(() {
      loading = true;
    });

    // create content object
    var content = {};
    if (pictureController.text != "") {
      content["picture"] = pictureController.text;
    }
    if (bannerController.text != "") {
      content["banner"] = bannerController.text;
    }
    if (nameController.text != "") {
      content["name"] = nameController.text;
    }
    if (nip05Controller.text != "") {
      content["nip05"] = nip05Controller.text;
    }
    if (aboutController.text != "") {
      content["about"] = aboutController.text;
    }
    if (websiteController.text != "") {
      content["website"] = websiteController.text;
    }

    var contentString = json.encode(content);

    widget._nostrService.writeEvent(contentString, 0, []);

    // update cache
    widget._nostrService.usersMetadata[pubkey] = content;

    Navigator.pop(context, "updated");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Palette.primary,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ListView(
                controller: _scrollController,
                children: <Widget>[
                  // profile image

                  Container(
                    margin: const EdgeInsets.all(10),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Palette.primary,
                        width: 3,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: CircleAvatar(
                        onBackgroundImageError: (exception, stackTrace) {
                          log("ok");
                        },
                        radius: 50,
                        backgroundImage: NetworkImage(
                          pictureController.text,
                          headers: {
                            'Cache-Control': 'no-cache',
                          },
                        ),
                      ),
                    ),
                  ),
                  // text input to edit profile image url
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: pictureController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Profile Image URL',
                      ),
                    ),
                  ),

                  // banner image

                  Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: bannerController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Banner Image URL',
                      ),
                    ),
                  ),

                  // text input to edit name
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                      ),
                    ),
                  ),
                  // text input to edit nip05
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: nip05Controller,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'NIP05',
                      ),
                    ),
                  ),
                  // text input to edit about
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: aboutController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'about',
                      ),
                    ),
                  ),
                  // text input to edit website
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: TextField(
                      controller: websiteController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Website',
                      ),
                    ),
                  ),
                  // button to save changes
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Palette.primary,
                        ),
                      ),
                      onPressed: () async {
                        _submitData();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                  // expandable information
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: ExpansionPanelList(
                      animationDuration: const Duration(milliseconds: 100),
                      expansionCallback: (int index, bool isExpanded) {
                        setState(() {
                          isExpanded = !isExpanded;
                          isKeysExpanded = isExpanded;
                        });
                        if (isKeysExpanded) {
                          // wait for expansion animation to finish
                          Future.delayed(const Duration(milliseconds: 100), () {
                            // scroll to bottom of page
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeOut,
                            );
                          });
                        }
                      },
                      children: [
                        ExpansionPanel(
                          headerBuilder:
                              (BuildContext context, bool isExpanded) {
                            return const ListTile(
                              title: Text('public & private key'),
                            );
                          },
                          body: Column(
                            children: [
                              // public key
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(5),
                                child: GestureDetector(
                                  onTap: () {
                                    copyToClipboard(widget
                                        ._nostrService.myKeys.publicKeyHr);
                                  },
                                  child: Text(
                                      widget._nostrService.myKeys.publicKeyHr),
                                ),
                              ),
                              // private key
                              Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(5),
                                child: GestureDetector(
                                  onTap: () {
                                    copyToClipboard(widget
                                        ._nostrService.myKeys.privateKeyHr);
                                  },
                                  child: Text(
                                      widget._nostrService.myKeys.privateKeyHr),
                                ),
                              ),
                            ],
                          ),
                          isExpanded: isKeysExpanded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }
}
