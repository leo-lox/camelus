import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

class CopyClipboardButton extends StatefulWidget {
  final String value;
  final String copyText;
  final String copyDoneText;

  final Color backgroundColor;

  const CopyClipboardButton({
    super.key,
    required this.value,
    this.copyText = 'Copy',
    this.copyDoneText = 'Copied to Clipboard!',
    this.backgroundColor = Colors.white,
  });

  @override
  State<CopyClipboardButton> createState() => _CopyClipboardButtonState();
}

class _CopyClipboardButtonState extends State<CopyClipboardButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _copied ? null : _copyToClipboard,
        icon: Icon(
          _copied ? PhosphorIcons.check : PhosphorIcons.copySimple,
        ),
        label: Text(_copied ? widget.copyDoneText : widget.copyText),
        style: ElevatedButton.styleFrom(
          backgroundColor: _copied
              ? widget.backgroundColor
              : Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: widget.backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.value));
    setState(() {
      _copied = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _copied = false;
        });
      }
    });
  }
}
