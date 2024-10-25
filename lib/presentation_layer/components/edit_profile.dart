import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/palette.dart';
import '../atoms/camer_upload.dart';

class EditProfile extends ConsumerStatefulWidget {
  final String initialName;
  final Function(String) onNameChanged;

  final Uint8List? initialPicture;
  final Function() pictureCallback;

  final Uint8List? initialBanner;
  final Function() bannerCallback;

  final String initalAbout;
  final Function(String) onAboutChanged;

  final String initialNip05;
  final Function(String) onNip05Changed;

  final String initialWebsite;
  final Function(String) onWebsiteChanged;

  final String initalLud06;
  final Function(String) onLud06Changed;

  final String initialLud16;
  final Function(String) onLud16Changed;

  const EditProfile({
    super.key,
    required this.initialName,
    required this.initialPicture,
    required this.initialBanner,
    required this.initalAbout,
    required this.initialNip05,
    required this.initialWebsite,
    required this.initalLud06,
    required this.initialLud16,
    required this.onNameChanged,
    required this.pictureCallback,
    required this.bannerCallback,
    required this.onAboutChanged,
    required this.onNip05Changed,
    required this.onWebsiteChanged,
    required this.onLud06Changed,
    required this.onLud16Changed,
  });

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  late TextEditingController _nameController;
  late TextEditingController _aboutController;
  late TextEditingController _nip05Controller;
  late TextEditingController _websiteController;
  late TextEditingController _lud06Controller;
  late TextEditingController _lud16Controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _aboutController = TextEditingController(text: widget.initalAbout);
    _nip05Controller = TextEditingController(text: widget.initialNip05);
    _websiteController = TextEditingController(text: widget.initialWebsite);
    _lud06Controller = TextEditingController(text: widget.initalLud06);
    _lud16Controller = TextEditingController(text: widget.initialLud16);

    // Add listeners to controllers
    _nameController
        .addListener(() => widget.onNameChanged(_nameController.text));
    _aboutController
        .addListener(() => widget.onAboutChanged(_aboutController.text));
    _nip05Controller
        .addListener(() => widget.onNip05Changed(_nip05Controller.text));
    _websiteController
        .addListener(() => widget.onWebsiteChanged(_websiteController.text));
    _lud06Controller
        .addListener(() => widget.onLud06Changed(_lud06Controller.text));
    _lud16Controller
        .addListener(() => widget.onLud16Changed(_lud16Controller.text));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    _nip05Controller.dispose();
    _websiteController.dispose();
    _lud06Controller.dispose();
    _lud16Controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: (MediaQuery.of(context).size.height / 6) + 60,
          child: Stack(
            children: <Widget>[
              InkWell(
                onTap: () {
                  log("Header Pressed");
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 6,
                  decoration: const BoxDecoration(
                    //shape: BoxShape.circle,
                    color: Palette.darkGray,
                  ),
                ),
              ),
              Positioned(
                top: 90,
                left: MediaQuery.of(context).size.width / 6,
                child: InkWell(
                    onTap: () {
                      log("CircleButtonPressed");
                    },
                    child: const CameraUpload(size: 100)),
              ),
            ],
          ),
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Container(
                /// color: Colors.red,
                child: Text(
                  "Name",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color.fromARGB(213, 245, 248, 250),
                    fontSize: MediaQuery.of(context).size.width / 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        TextField(
          controller: _nameController,
          decoration: textEditInputDecoration,
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Container(
                /// color: Colors.red,
                child: Text(
                  "Bio",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color.fromARGB(213, 245, 248, 250),
                    fontSize: MediaQuery.of(context).size.width / 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        TextField(
          controller: _aboutController,
          decoration: textEditInputDecoration,
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Container(
                /// color: Colors.red,
                child: Text(
                  "Location",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color.fromARGB(213, 245, 248, 250),
                    fontSize: MediaQuery.of(context).size.width / 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        TextField(
          decoration: textEditInputDecoration,
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Container(
                /// color: Colors.red,
                child: Text(
                  "Website",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color.fromARGB(213, 245, 248, 250),
                    fontSize: MediaQuery.of(context).size.width / 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        TextField(
          decoration: textEditInputDecoration,
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Container(
                /// color: Colors.red,
                child: Text(
                  "Birth date",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color.fromARGB(213, 245, 248, 250),
                    fontSize: MediaQuery.of(context).size.width / 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        TextField(
          decoration: textEditInputDecoration,
        ),
        Column(
          children: <Widget>[
            SizedBox(
              width: double.infinity,
              child: Container(
                /// color: Colors.red,
                child: Text(
                  "Pronouns",
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    color: const Color.fromARGB(213, 245, 248, 250),
                    fontSize: MediaQuery.of(context).size.width / 28,
                  ),
                ),
              ),
            ),
          ],
        ),
        TextField(
          decoration: textEditInputDecoration,
        ),
      ],
    );
  }
}

const textEditInputDecoration = InputDecoration(
  hintText: "",
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      width: 1, //<-- SEE HERE
      color: Colors.grey,
    ),
  ),
);
