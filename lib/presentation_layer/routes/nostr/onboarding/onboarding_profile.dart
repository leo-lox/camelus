import 'dart:io';
import 'dart:typed_data';

import 'package:camelus/presentation_layer/components/edit_profile.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime/mime.dart';

import '../../../../domain_layer/entities/mem_file.dart';
import '../../../../domain_layer/entities/onboarding_user_info.dart';
import '../../../atoms/crop_avatar.dart';
import '../../../atoms/long_button.dart';

class OnboardingProfile extends ConsumerStatefulWidget {
  final OnboardingUserInfo signUpInfo;
  final Function profileCallback;

  const OnboardingProfile({
    super.key,
    required this.signUpInfo,
    required this.profileCallback,
  });

  @override
  ConsumerState<OnboardingProfile> createState() => _OnboardingProfileState();
}

class _OnboardingProfileState extends ConsumerState<OnboardingProfile> {
  Future<MemFile?> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.image,
      dialogTitle: "select image",
    );

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

      return memFile;
    } else {
      // User canceled the picker
      return null;
    }
  }

  _openCropImagePopup({
    required Uint8List imageData,
    required Function(Uint8List) callback,
    double aspectRatio = 1,
    bool roundUi = true,
  }) {
    // push fullscreen widget
    Navigator.push(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (context) => CropAvatar(
          roundUi: roundUi,
          aspectRatio: aspectRatio,
          imageData: imageData,
        ),
      ),
    ).then((value) {
      if (value != null) {
        callback(value);
      }
    });
  }

  /// pick a new picture and crop
  _onClickPicture() async {
    final file = await _pickFile();
    if (file == null) return;

    _openCropImagePopup(
      imageData: file.bytes,
      callback: (croppedData) => {
        setState(() {
          widget.signUpInfo.picture = MemFile(
            bytes: croppedData,
            mimeType: file.mimeType,
            name: file.name,
          );
        }),
      },
    );
  }

  /// pick a new banner and crop
  _onClickBanner() async {
    final file = await _pickFile();
    if (file == null) return;

    _openCropImagePopup(
      aspectRatio: 16 / 6,
      imageData: file.bytes,
      roundUi: false,
      callback: (croppedData) => {
        setState(() {
          widget.signUpInfo.banner = MemFile(
            bytes: croppedData,
            mimeType: file.mimeType,
            name: file.name,
          );
        })
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80),
                child: EditProfile(
                  initialName: widget.signUpInfo.name ?? '',
                  onNameChanged: (value) {
                    widget.signUpInfo.name = value;
                  },
                  initialPicture: widget.signUpInfo.picture?.bytes,
                  pictureCallback: () => _onClickPicture(),
                  initialBanner: widget.signUpInfo.banner?.bytes,
                  bannerCallback: () => _onClickBanner(),
                  initialAbout: widget.signUpInfo.about ?? '',
                  onAboutChanged: (value) {
                    widget.signUpInfo.about = value;
                  },
                  initialNip05: widget.signUpInfo.nip05 ?? '',
                  onNip05Changed: (value) {
                    widget.signUpInfo.nip05 = value;
                  },
                  initialWebsite: widget.signUpInfo.website ?? '',
                  onWebsiteChanged: (value) {
                    widget.signUpInfo.website = value;
                  },
                  initialLud06: widget.signUpInfo.lud06,
                  onLud06Changed: (value) {
                    widget.signUpInfo.lud06 = value;
                  },
                  initialLud16: widget.signUpInfo.lud16,
                  onLud16Changed: (value) {
                    widget.signUpInfo.lud16 = value;
                  },
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: 400,
                  height: 40,
                  child: longButton(
                    name: "next",
                    onPressed: (() {
                      FocusScope.of(context).unfocus();
                      widget.profileCallback();
                    }),
                    inverted: true,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
