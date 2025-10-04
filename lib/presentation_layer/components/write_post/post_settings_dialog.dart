import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../config/palette.dart';

class PostSettingsState {
  final bool enableContentWarning;
  final bool enableClientTag;
  final String selectedWarning;
  final String customWarning;

  String get warning =>
      selectedWarning == 'Other' ? customWarning : selectedWarning;

  PostSettingsState({
    this.enableContentWarning = false,
    this.enableClientTag = true,
    this.selectedWarning = 'Sensitive Content',
    this.customWarning = '',
  });

  PostSettingsState copyWith({
    bool? enableContentWarning,
    bool? enableClientTag,
    String? selectedWarning,
    String? customWarning,
  }) {
    return PostSettingsState(
      enableContentWarning: enableContentWarning ?? this.enableContentWarning,
      enableClientTag: enableClientTag ?? this.enableClientTag,
      selectedWarning: selectedWarning ?? this.selectedWarning,
      customWarning: customWarning ?? this.customWarning,
    );
  }
}

class PostSettingsNotifier extends StateNotifier<PostSettingsState> {
  PostSettingsNotifier() : super(PostSettingsState());

  void toggleContentWarning(bool value) {
    state = state.copyWith(enableContentWarning: value);
  }

  void toggleClientTag(bool value) {
    state = state.copyWith(enableClientTag: value);
  }

  void setSelectedWarning(String warning) {
    state = state.copyWith(selectedWarning: warning);
  }

  void setCustomWarning(String warning) {
    state = state.copyWith(customWarning: warning);
  }

  void reset() {
    state = PostSettingsState();
  }
}

final postSettingsProvider =
    StateNotifierProvider<PostSettingsNotifier, PostSettingsState>((ref) {
  return PostSettingsNotifier();
});

class PostSettings extends ConsumerStatefulWidget {
  const PostSettings({
    super.key,
  });

  @override
  ConsumerState<PostSettings> createState() => _PostSettingsState();
}

class _PostSettingsState extends ConsumerState<PostSettings> {
  late TextEditingController _customWarningController;

  static const List<String> warningOptions = [
    'Sensitive Content',
    'Flashing Lights/Patterns',
    'Loud Noises',
    'Graphic Content',
    'Discrimination',
    'Health',
    'Abuse',
    'Other'
  ];

  @override
  void initState() {
    super.initState();

    _customWarningController = TextEditingController(
      text: ref.read(postSettingsProvider).customWarning,
    );
  }

  @override
  void dispose() {
    _customWarningController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(postSettingsProvider);
    final notifier = ref.read(postSettingsProvider.notifier);

    if (_customWarningController.text != state.customWarning) {
      _customWarningController.text = state.customWarning;
    }

    return AlertDialog(
      backgroundColor: Paletter.getExtraDarkGray(context),
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text('Post Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Warning Switch
            _buildSwitchRow(
              title: 'Enable Content Warning',
              value: state.enableContentWarning,
              onChanged: (value) {
                notifier.toggleContentWarning(value);
              },
            ),

            // Only show dropdown if content warning is enabled
            if (state.enableContentWarning) ...[
              const SizedBox(height: 16),
              const Text(
                'Warning Type:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDropdown(
                context,
                state,
                notifier,
              ),

              // Add custom warning text field if "Other" is selected
              if (state.selectedWarning == 'Other') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _customWarningController,
                  decoration: InputDecoration(
                    labelText: 'Custom Warning',
                    hintText: 'Specify content warning',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    notifier.setCustomWarning(value);
                  },
                ),
              ],
            ],

            const SizedBox(height: 16),
            Divider(
              color: Paletter.getDarkGray(context),
            ),
            const SizedBox(height: 16),

            // Client Tag Switch
            _buildSwitchRow(
              title: 'Enable Client Tag',
              value: state.enableClientTag,
              onChanged: (value) {
                notifier.toggleClientTag(value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Paletter.getWhite(context),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    PostSettingsState state,
    PostSettingsNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Paletter.getGray(context)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Paletter.getExtraDarkGray(context),
          value: state.selectedWarning,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
          onChanged: (String? newValue) {
            if (newValue != null) {
              notifier.setSelectedWarning(newValue);
            }
          },
          items: warningOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Paletter.getWhite(context),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
