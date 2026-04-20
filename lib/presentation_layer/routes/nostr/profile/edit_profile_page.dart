import 'dart:async';

import 'package:camelus/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain_layer/entities/mem_file.dart';
import '../../../../domain_layer/entities/user_metadata.dart';
import '../../../atoms/crop_avatar.dart';
import '../../../atoms/long_button.dart';
import '../../../atoms/spinner_center.dart';
import '../../../components/edit_profile.dart';
import '../../../providers/file_upload_provider.dart';
import '../../../providers/metadata_provider.dart';
import '../../../providers/metadata_state_provider.dart';

class ProfileState {
  final String pubkey;
  final String name;
  final String about;
  final String nip05;
  final String website;
  final String lud06;
  final String lud16;
  final String pronouns;
  final String? profilePictureUrl;
  final String? bannerPictureUrl;
  final bool isLoading;
  final bool isSaving;
  final bool isUploadingProfile;
  final bool isUploadingBanner;
  final Uint8List? profilePictureData;
  final Uint8List? bannerPictureData;
  final String? profilePictureErr;
  final String? bannerPictureErr;
  final String? errBroadcasting;

  ProfileState({
    required this.pubkey,
    required this.name,
    required this.about,
    required this.nip05,
    required this.website,
    required this.lud06,
    required this.lud16,
    required this.pronouns,
    this.profilePictureUrl,
    this.bannerPictureUrl,
    this.profilePictureData,
    this.bannerPictureData,
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingProfile = false,
    this.isUploadingBanner = false,
    this.bannerPictureErr,
    this.profilePictureErr,
    this.errBroadcasting,
  });

  ProfileState copyWith({
    String? pubkey,
    String? name,
    String? about,
    String? nip05,
    String? website,
    String? lud06,
    String? lud16,
    String? pronouns,
    String? profilePictureUrl,
    String? bannerPictureUrl,
    Uint8List? profilePictureData,
    String? profilePictureErr,
    Uint8List? bannerPictureData,
    String? bannerPictureErr,
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingProfile,
    bool? isUploadingBanner,
    String? errBroadcasting,
  }) {
    return ProfileState(
      pubkey: pubkey ?? this.pubkey,
      name: name ?? this.name,
      about: about ?? this.about,
      nip05: nip05 ?? this.nip05,
      website: website ?? this.website,
      lud06: lud06 ?? this.lud06,
      lud16: lud16 ?? this.lud16,
      pronouns: pronouns ?? this.pronouns,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      bannerPictureUrl: bannerPictureUrl ?? this.bannerPictureUrl,
      profilePictureData: profilePictureData ?? this.profilePictureData,
      bannerPictureData: bannerPictureData ?? this.bannerPictureData,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingProfile: isUploadingProfile ?? this.isUploadingProfile,
      isUploadingBanner: isUploadingBanner ?? this.isUploadingBanner,
      bannerPictureErr: bannerPictureErr ?? this.bannerPictureErr,
      profilePictureErr: profilePictureErr ?? this.profilePictureErr,
      errBroadcasting: errBroadcasting ?? this.errBroadcasting,
    );
  }
}

// Notifier class to manage profile state
class ProfileNotifier extends Notifier<ProfileState> {
  final String pubkey;
  ProfileNotifier(this.pubkey);

  @override
  ProfileState build() {
    return ProfileState(
      pubkey: pubkey,
      name: '',
      about: '',
      nip05: '',
      website: '',
      lud06: '',
      lud16: '',
      pronouns: '',
      isLoading: true,
    );
  }

  // Methods to update individual profile fields
  void updateName(String name) {
    state = state.copyWith(name: name);
  }

  void updateAbout(String about) {
    state = state.copyWith(about: about);
  }

  void updateNip05(String nip05) {
    state = state.copyWith(nip05: nip05);
  }

  void updateWebsite(String website) {
    state = state.copyWith(website: website);
  }

  void updateLud06(String lud06) {
    state = state.copyWith(lud06: lud06);
  }

  void updateLud16(String lud16) {
    state = state.copyWith(lud16: lud16);
  }

  void updatePronouns(String pronouns) {
    state = state.copyWith(pronouns: pronouns);
  }

  Future<void> uploadProfilePicture(MemFile imageFile) async {
    try {
      // Set uploading state to true
      state = state.copyWith(isUploadingProfile: true);
      ref.read(editProfilePictureUploadingProvider.notifier).setUploading(true);

      // insert picture
      state = state.copyWith(profilePictureData: imageFile.bytes);

      //upload
      final uploadResult = await ref
          .read(fileUploadProvider)
          .uploadImage(imageFile);
      final hostedImageUrl = uploadResult
          .firstWhere((e) => e.descriptor?.url.isNotEmpty == true)
          .descriptor
          ?.url;

      // Update state with the new URL
      if (hostedImageUrl != null) {
        state = state.copyWith(
          profilePictureUrl: hostedImageUrl,
          isUploadingProfile: false,
        );
      } else {
        // Handle upload failure
        state = state.copyWith(
          isUploadingProfile: false,
          profilePictureData: null,
          profilePictureErr: "errorUploadingImage",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isUploadingProfile: false,
        profilePictureData: null,
        profilePictureErr: e.toString(),
      );
    }
    ref.read(editProfilePictureUploadingProvider.notifier).setUploading(false);
  }

  Future<void> uploadBannerPicture(MemFile imageFile) async {
    try {
      // Set uploading state to true
      state = state.copyWith(isUploadingBanner: true);
      ref.read(editProfileBannerUploadingProvider.notifier).setUploading(true);

      state = state.copyWith(bannerPictureData: imageFile.bytes);

      // Upload  image
      final uploadResult = await ref
          .read(fileUploadProvider)
          .uploadImage(imageFile);
      final hostedImageUrl = uploadResult
          .firstWhere((e) => e.descriptor?.url.isNotEmpty == true)
          .descriptor
          ?.url;

      // Update state with the new URL
      if (hostedImageUrl != null) {
        state = state.copyWith(
          bannerPictureUrl: hostedImageUrl,
          isUploadingBanner: false,
        );
      } else {
        // Handle upload failure
        state = state.copyWith(
          isUploadingBanner: false,
          bannerPictureData: null,
          bannerPictureErr: "errorUploadingImage",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isUploadingBanner: false,
        bannerPictureData: null,
        bannerPictureErr: e.toString(),
      );
    }
    ref.read(editProfileBannerUploadingProvider.notifier).setUploading(false);
  }

  Future<void> saveProfile() async {
    try {
      state = state.copyWith(isSaving: true);

      final UserMetadata userMetadata = UserMetadata(
        eventId: '',
        lastFetch: 0,
        pubkey: state.pubkey,
        name: state.name,
        picture: state.profilePictureUrl,
        banner: state.bannerPictureUrl,
        about: state.about,
        pronouns: state.pronouns,
        website: state.website,
        nip05: state.nip05,
        lud06: state.lud06,
        lud16: state.lud16,
      );
      final metadataP = ref.read(metadataProvider);
      final newMetadata = await metadataP.broadcastMetadata(userMetadata);

      // update app metadata about user
      ref
          .read(metadataStateProvider(state.pubkey).notifier)
          .setMetadata(newMetadata);
    } catch (e) {
      state.copyWith(errBroadcasting: e.toString(), isSaving: false);
    } finally {
      state = state.copyWith(isSaving: false);
    }
  }

  // Method to load profile data from the metadataStateProvider
  Future<void> loadProfile() async {
    try {
      // Set loading state to true
      state = state.copyWith(isLoading: true);

      // Get metadata from the metadataStateProvider
      final myMetadata = ref
          .read(metadataStateProvider(state.pubkey))
          .userMetadata;
      final metadataProv = ref.read(metadataProvider);

      if (myMetadata != null) {
        Uint8List? profilePicData;
        Uint8List? bannerPicData;

        // fetch images
        if (myMetadata.picture != null && myMetadata.picture!.isNotEmpty) {
          metadataProv
              .downloadImageUrl(myMetadata.picture!)
              .then(
                (data) => {state = state.copyWith(profilePictureData: data)},
              );
        }
        if (myMetadata.banner != null && myMetadata.banner!.isNotEmpty) {
          metadataProv
              .downloadImageUrl(myMetadata.banner!)
              .then(
                (data) => {state = state.copyWith(bannerPictureData: data)},
              );
        }

        // Update state with metadata
        state = state.copyWith(
          name: myMetadata.name ?? '',
          about: myMetadata.about ?? '',
          nip05: myMetadata.nip05 ?? '',
          website: myMetadata.website ?? '',
          lud06: myMetadata.lud06 ?? '',
          lud16: myMetadata.lud16 ?? '',
          pronouns: myMetadata.pronouns ?? '',
          profilePictureUrl: myMetadata.picture,
          bannerPictureUrl: myMetadata.banner,
          profilePictureData: profilePicData,
          bannerPictureData: bannerPicData,
          isLoading: false,
        );
      } else {
        // If metadata is null, set default empty values
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Provider for the profile state that takes a pubkey parameter
final profileProvider =
    NotifierProvider.family<ProfileNotifier, ProfileState, String>(
      ProfileNotifier.new,
    );

class EditProfilePage extends ConsumerStatefulWidget {
  final String pubkey;

  const EditProfilePage({super.key, required this.pubkey});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load profile data when the page is initialized
    Future.microtask(
      () => ref.read(profileProvider(widget.pubkey).notifier).loadProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider(widget.pubkey));

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editProfile),
        actions: [
          Text(
            "${profileState.errBroadcasting ?? ''} ${profileState.profilePictureErr ?? ''} ${profileState.bannerPictureErr ?? ''}",
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(width: 10),
          profileState.isSaving
              ? Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.only(right: 11),
                  child: longButton(
                    name: AppLocalizations.of(context)!.save,
                    inverted: true,
                    onPressed: () async {
                      await ref
                          .read(profileProvider(widget.pubkey).notifier)
                          .saveProfile();
                      if (mounted && !profileState.isSaving) {
                        context.pop();
                      }
                    },
                  ),
                ),
          if (!kIsWeb &&
              (defaultTargetPlatform == TargetPlatform.windows ||
                  defaultTargetPlatform == TargetPlatform.linux ||
                  defaultTargetPlatform == TargetPlatform.macOS))
            const SizedBox(width: 154),
        ],
      ),
      body: profileState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SpinnerCenter(),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.loadingProfile,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: EditProfile(
                initialName: profileState.name,
                onNameChanged: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updateName(value),
                initialPicture: profileState.profilePictureData,
                pictureCallback: () async {
                  _pickImageEditPopup(
                    aspectRatio: 1,
                    resize: true,
                    targetWidth: 250,
                  ).then((value) async {
                    if (value != null) {
                      await ref
                          .read(profileProvider(widget.pubkey).notifier)
                          .uploadProfilePicture(value);
                    }
                  });
                },
                initialBanner: profileState.bannerPictureData,
                bannerCallback: () async {
                  _pickImageEditPopup(
                    resize: true,
                    targetWidth: 450,
                    aspectRatio: 16 / 6,
                    roundUi: false,
                  ).then((value) async {
                    if (value != null) {
                      await ref
                          .read(profileProvider(widget.pubkey).notifier)
                          .uploadBannerPicture(value);
                    }
                  });
                },
                initialAbout: profileState.about,
                onAboutChanged: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updateAbout(value),
                initialNip05: profileState.nip05,
                onNip05Changed: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updateNip05(value),
                initialWebsite: profileState.website,
                onWebsiteChanged: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updateWebsite(value),
                initialLud06: profileState.lud06,
                onLud06Changed: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updateLud06(value),
                initialLud16: profileState.lud16,
                onLud16Changed: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updateLud16(value),
                initialPronouns: profileState.pronouns,
                onPronounsChanged: (value) => ref
                    .read(profileProvider(widget.pubkey).notifier)
                    .updatePronouns(value),
              ),
            ),
    );
  }

  Future<XFile?> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery);
    return result;
  }

  Future<MemFile?> _pickImageEditPopup({
    double aspectRatio = 1,
    bool roundUi = true,
    bool resize = true,
    int targetWidth = 250,
  }) async {
    final pickedImage = await _pickImage();

    if (pickedImage != null) {
      final uneditedImage = await pickedImage.readAsBytes();

      final completer = Completer<MemFile?>();

      _openCropImagePopup(
        resize: resize,
        targetWidth: targetWidth,
        aspectRatio: aspectRatio,
        roundUi: roundUi,
        imageData: uneditedImage,
        callback: (imageData) async {
          final editedFile = MemFile(
            bytes: imageData,
            mimeType: pickedImage.mimeType ?? '',
            name: pickedImage.name,
          );

          completer.complete(editedFile);
        },
      );

      return completer.future;
    }
    return null;
  }

  void _openCropImagePopup({
    required Uint8List imageData,
    required Function(Uint8List) callback,
    double aspectRatio = 1,
    bool roundUi = true,
    bool resize = true,
    int targetWidth = 250,
  }) {
    // push fullscreen widget
    Navigator.push(
      context,
      MaterialPageRoute<Uint8List>(
        builder: (context) => CropAvatar(
          resize: resize,
          targetWidth: targetWidth,
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
}
