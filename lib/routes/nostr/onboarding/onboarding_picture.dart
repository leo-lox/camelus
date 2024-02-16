import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:camelus/atoms/crop_avatar.dart';
import 'package:camelus/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/models/onboarding_user_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OnboardingPicture extends ConsumerStatefulWidget {
  final Function pictureCallback;

  OnboardingUserInfo signUpInfo;

  OnboardingPicture({
    Key? key,
    required this.pictureCallback,
    required this.signUpInfo,
  }) : super(key: key);
  @override
  ConsumerState<OnboardingPicture> createState() => _OnboardingPictureState();
}

class _OnboardingPictureState extends ConsumerState<OnboardingPicture> {
  _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      Uint8List imageData = file.readAsBytesSync();
      _openCropImagePopup(imageData);
    } else {
      // User canceled the picker
      return;
    }
  }

  _openCropImagePopup(Uint8List imageData) {
    // push fullscreen widget
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CropAvatar(
          imageData: imageData,
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          widget.signUpInfo.picture = value;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextButton(
              onPressed: () {
                _pickFile();
              },
              child: Text("test")),
          if (widget.signUpInfo.picture == null)
            myProfilePicture(
              pubkey: widget.signUpInfo.keyPair.publicKey,
              pictureUrl: "",
            ),
          if (widget.signUpInfo.picture != null)
            SizedBox.fromSize(
              size: const Size.fromRadius(30), // Image radius
              child: Image(image: MemoryImage(widget.signUpInfo.picture!)),
            )
        ],
      ),
    );
  }
}
