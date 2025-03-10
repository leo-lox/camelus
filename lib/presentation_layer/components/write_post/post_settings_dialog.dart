import 'package:flutter/material.dart';

import '../../../config/palette.dart';

class PostSettings extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSettingsChanged;

  const PostSettings({
    super.key,
    this.onSettingsChanged,
  });

  @override
  PostSettingsState createState() => PostSettingsState();
}

class PostSettingsState extends State<PostSettings> {
  bool enableContentWarning = false;
  bool enableClientTag = false;
  String selectedWarning = 'Sensitive Content';
  String customWarning = '';

  // List of common content warning options
  final List<String> warningOptions = [
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
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Palette.extraDarkGray,
      elevation: 24,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text('Post Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Content Warning Switch
            _buildSwitchRow(
              title: 'Enable Content Warning',
              value: enableContentWarning,
              onChanged: (value) {
                setState(() {
                  enableContentWarning = value;
                });
              },
            ),

            // Only show dropdown if content warning is enabled
            if (enableContentWarning) ...[
              SizedBox(height: 16),
              Text(
                'Warning Type:',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              _buildDropdown(),

              // Add custom warning text field if "Other" is selected
              if (selectedWarning == 'Other') ...[
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Custom Warning',
                    hintText: 'Specify content warning',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    customWarning = value;
                  },
                ),
              ],
            ],

            SizedBox(height: 16),
            Divider(
              color: Palette.darkGray,
            ),
            SizedBox(height: 16),

            // Client Tag Switch
            _buildSwitchRow(
              title: 'Enable Client Tag',
              value: enableClientTag,
              onChanged: (value) {
                setState(() {
                  enableClientTag = value;
                });
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
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Return the selected values
            final settings = {
              'contentWarning': {
                'enabled': enableContentWarning,
                'warningType': selectedWarning,
                'customWarning': customWarning,
              },
              'clientTag': {
                'enabled': enableClientTag,
              },
            };

            if (widget.onSettingsChanged != null) {
              widget.onSettingsChanged!(settings);
            }

            Navigator.of(context).pop(settings);
          },
          child: Text('Apply'),
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
          style: TextStyle(fontSize: 16),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Palette.gray),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          dropdownColor: Palette.extraDarkGray,
          value: selectedWarning,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down),
          elevation: 16,
          style: TextStyle(color: Colors.black87, fontSize: 16),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                selectedWarning = newValue;
              });
            }
          },
          items: warningOptions.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Palette.white,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
