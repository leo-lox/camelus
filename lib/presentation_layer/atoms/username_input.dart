import 'package:flutter/material.dart';

import '../../config/palette.dart';

class UsernameInputField extends StatefulWidget {
  final String username;
  final String domain;
  final Widget? trailing;

  final Function(String) onChange;

  const UsernameInputField({
    super.key,
    required this.username,
    required this.domain,
    required this.onChange,
    this.trailing,
  });

  @override
  State<UsernameInputField> createState() => _UsernameInputFieldState();
}

class _UsernameInputFieldState extends State<UsernameInputField> {
  final FocusNode _nameFocusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.username;
  }

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(UsernameInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.username != oldWidget.username) {
      _nameController.text = widget.username;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: MediaQuery.of(context).size.width * 0.95,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: IntrinsicWidth(
              child: TextField(
                textAlign: TextAlign.left,
                cursorRadius: const Radius.circular(50),
                maxLines: 1,
                textAlignVertical: TextAlignVertical.center,
                autofocus: true,
                focusNode: _nameFocusNode,
                controller: _nameController,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  hintText: '_',
                  contentPadding: EdgeInsets.all(0),
                  hintStyle: TextStyle(
                    color: Palette.white,
                    letterSpacing: 1.1,
                  ),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  widget.onChange(value);
                },
                style: const TextStyle(
                  color: Palette.lightGray,
                  letterSpacing: 1.1,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          Text(
            widget.domain,
            style: const TextStyle(
              color: Palette.gray,
              letterSpacing: 1.1,
              fontSize: 28,
            ),
          ),
          if (widget.trailing != null) widget.trailing!
        ],
      ),
    );
  }
}
