import 'dart:io';
import 'dart:typed_data';

import 'package:camelus/domain_layer/entities/mem_file.dart';
import 'package:camelus/presentation_layer/atoms/crop_avatar.dart';
import 'package:camelus/presentation_layer/atoms/my_profile_picture.dart';
import 'package:camelus/config/palette.dart';
import 'package:camelus/domain_layer/entities/onboarding_user_info.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mime/mime.dart';

class OnboardingPicture extends ConsumerStatefulWidget {
  final Function pictureCallback;

  OnboardingUserInfo signUpInfo;

  OnboardingPicture({
    super.key,
    required this.pictureCallback,
    required this.signUpInfo,
  });
  @override
  ConsumerState<OnboardingPicture> createState() => _OnboardingPictureState();
}

class _OnboardingPictureState extends ConsumerState<OnboardingPicture> {
  _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);

      Uint8List imageData = file.readAsBytesSync();
      String imageMimeType = lookupMimeType(file.path) ?? '';
      String imageName = file.path.split('/').last;

      MemFile memFile = MemFile(
        bytes: imageData,
        mimeType: imageMimeType,
        name: imageName,
      );
      widget.signUpInfo.picture = memFile;
      _openCropImagePopup(memFile.bytes);
    } else {
      // User canceled the picker
      return;
    }
  }

  Uint8List? _displayImage;

  _openCropImagePopup(Uint8List imageData) {
    // push fullscreen widget
    Navigator.push(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (context) => CropAvatar(
          imageData: imageData,
        ),
      ),
    ).then((value) {
      if (value != null) {
        setState(() {
          widget.signUpInfo.picture!.bytes = value;
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
              child: const Text("test")),
          if (widget.signUpInfo.picture == null)
            UserImage(
              imageUrl: null,
              pubkey: widget.signUpInfo.keyPair.publicKey,
            ),
          if (widget.signUpInfo.picture?.bytes != null)
            SizedBox.fromSize(
              size: const Size.fromRadius(30), // Image radius
              child: Image.memory(widget.signUpInfo.picture!.bytes),
            ),
        ],
      ),
    );
  }
}
