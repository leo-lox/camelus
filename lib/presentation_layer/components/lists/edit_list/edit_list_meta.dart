import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../domain_layer/entities/list_identifier.dart';
import '../../../../domain_layer/entities/mem_file.dart';
import '../../../../domain_layer/entities/nostr_list.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../atoms/crop_avatar.dart';
import '../../../atoms/icon_patter.dart';
import '../../../atoms/long_button.dart';
import '../../../providers/file_upload_provider.dart';
import 'edit_list_provider.dart';

class EditListMeta extends ConsumerStatefulWidget {
  final ListIdentifier listIdentifier;
  final bool isNewList;
  final VoidCallback onNext;

  const EditListMeta({
    super.key,
    required this.listIdentifier,
    required this.isNewList,
    required this.onNext,
  });

  @override
  ConsumerState<EditListMeta> createState() => _EditListMetaState();
}

class _EditListMetaState extends ConsumerState<EditListMeta> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = ref.read(editListProvider(widget.listIdentifier));
      _titleController.text = data.title;
      _descriptionController.text = data.description ?? '';
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickImage() async {
    final picker = ImagePicker();
    return picker.pickImage(source: ImageSource.gallery);
  }

  Future<void> _bannerUpload() async {
    final pickedImage = await _pickImage();
    if (pickedImage == null) return;
    final uneditedBytes = await pickedImage.readAsBytes();
    if (!mounted) return;

    Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (context) => CropAvatar(
          resize: true,
          targetWidth: 400,
          roundUi: false,
          aspectRatio: 16 / 6,
          buttonText: AppLocalizations.of(context)!.upload,
          imageData: uneditedBytes,
        ),
      ),
    ).then((value) async {
      if (value == null) return;
      final notifier = ref.read(
        editListProvider(widget.listIdentifier).notifier,
      );
      notifier.updateImage(imageUploading: true);

      final editedFile = MemFile(
        bytes: value,
        mimeType: pickedImage.mimeType ?? '',
        name: pickedImage.name,
      );
      final imageUrl = await _uploadImage(editedFile);
      if (imageUrl == null) {
        notifier.updateImage(imageUploading: false);
        return;
      }
      notifier.updateImage(imageUploading: false, imageUrl: imageUrl);
    });
  }

  Future<String?> _uploadImage(MemFile imageData) async {
    final result = await ref.read(fileUploadProvider).uploadImage(imageData);
    return result
        .firstWhere((e) => e.descriptor?.url.isNotEmpty == true)
        .descriptor
        ?.url;
  }

  String _kindLabel(BuildContext context, int kind) {
    if (kind == NostrList.followSet) {
      return AppLocalizations.of(context)!.followSetKind;
    }
    if (kind == NostrList.starterPack) {
      return AppLocalizations.of(context)!.starterPackKind;
    }
    return AppLocalizations.of(context)!.curationSetKind;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(editListProvider(widget.listIdentifier));
    final notifier = ref.watch(
      editListProvider(widget.listIdentifier).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isNewList
              ? AppLocalizations.of(context)!.createNewList
              : AppLocalizations.of(context)!.lists,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Kind badge (read-only when editing existing)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _kindLabel(context, widget.listIdentifier.kind),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Banner image
                  Center(
                    child: GestureDetector(
                      onTap: _bannerUpload,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 100,
                          maxWidth: 350,
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 6,
                          child: Stack(
                            children: [
                              data.imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        data.imageUrl!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : IconPattern(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                              if (data.imageUploading)
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Theme.of(context).colorScheme.surface
                                        .withValues(alpha: 0.6),
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          AppLocalizations.of(
                                            context,
                                          )!.uploading,
                                          style: TextStyle(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Title field
                  Text(
                    AppLocalizations.of(context)!.listTitle,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    maxLength: 40,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      counterText: '${notifier.titleCharacterCount}/40',
                    ),
                    onChanged: notifier.updateTitle,
                  ),

                  const SizedBox(height: 16),

                  // Description field
                  Text(
                    AppLocalizations.of(context)!.listDescription,
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: notifier.updateDescription,
                  ),
                ],
              ),
            ),
          ),

          // Continue button
          Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: longButton(
                  name: AppLocalizations.of(context)!.next,
                  inverted: true,
                  disabled: !notifier.isTitleValid,
                  onPressed: widget.onNext,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
