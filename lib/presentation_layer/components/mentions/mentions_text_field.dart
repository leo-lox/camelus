import 'package:material_ui/material_ui.dart';

class MentionsTextField extends StatefulWidget {
  const MentionsTextField({
    super.key,
    required this.focusNode,
    required this.textStyle,
    required this.hintText,
    required this.hintStyle,
    required this.onMarkupChanged,
    required this.onSearchChanged,
    required this.mentionData,
    required this.suggestionBuilder,
  });

  final FocusNode focusNode;
  final TextStyle textStyle;
  final String hintText;
  final TextStyle hintStyle;
  final ValueChanged<String> onMarkupChanged;
  final void Function(String trigger, String search) onSearchChanged;
  final Map<String, List<Map<String, dynamic>>> mentionData;
  final Widget Function(String trigger, Map<String, dynamic> data)
  suggestionBuilder;

  @override
  State<MentionsTextField> createState() => MentionsTextFieldState();
}

class MentionsTextFieldState extends State<MentionsTextField> {
  final TextEditingController controller = TextEditingController();
  final Map<String, String> _mentionIds = {};
  String? _activeTrigger;
  String _activeSearch = '';
  int _triggerStart = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_handleTextChanged);
    controller.dispose();
    super.dispose();
  }

  void setMarkupText(String markupText) {
    final mentions = RegExp(r'@\[__(.*?)__\]\(__(.+?)__\)');
    _mentionIds.clear();
    controller.text = markupText.replaceAllMapped(mentions, (match) {
      final display = match.group(2)!;
      _mentionIds[display] = match.group(1)!;
      return '@$display';
    });
  }

  void _handleTextChanged() {
    final selection = controller.selection;
    final prefix = selection.isValid
        ? controller.text.substring(0, selection.baseOffset)
        : controller.text;
    final match = RegExp(r'(^|\s)([@#])(\w*)$').firstMatch(prefix);

    setState(() {
      _activeTrigger = match?.group(2);
      _activeSearch = match?.group(3) ?? '';
      _triggerStart = match == null
          ? 0
          : prefix.length - match.group(3)!.length - 1;
    });

    if (_activeTrigger != null) {
      widget.onSearchChanged(_activeTrigger!, match!.group(3)!);
    }
    widget.onMarkupChanged(_markupText);
  }

  String get _markupText {
    var markup = controller.text;
    for (final entry in _mentionIds.entries) {
      markup = markup.replaceAllMapped(
        RegExp('@${RegExp.escape(entry.key)}(?=\\s|\$)'),
        (_) => '@[__${entry.value}__](__${entry.key}__)',
      );
    }
    return markup;
  }

  void _selectSuggestion(Map<String, dynamic> suggestion) {
    final trigger = _activeTrigger!;
    final display = suggestion['display'] as String? ?? '';
    if (display.isEmpty) return;

    if (trigger == '@') {
      final id = suggestion['id'] as String?;
      if (id == null || id.isEmpty) return;
      _mentionIds[display] = id;
    }

    final selection = controller.selection;
    final replacement = '$trigger$display ';
    controller.value = controller.value.copyWith(
      text: controller.text.replaceRange(
        _triggerStart,
        selection.baseOffset,
        replacement,
      ),
      selection: TextSelection.collapsed(
        offset: _triggerStart + replacement.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _activeTrigger == null || _activeSearch.isEmpty
        ? const <Map<String, dynamic>>[]
        : widget.mentionData[_activeTrigger]!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          focusNode: widget.focusNode,
          keyboardType: TextInputType.multiline,
          keyboardAppearance: Brightness.dark,
          style: widget.textStyle,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.hintText,
            hintStyle: widget.hintStyle,
          ),
          maxLines: 10,
          minLines: 5,
        ),
        if (suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: suggestions.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => _selectSuggestion(suggestions[index]),
                child: widget.suggestionBuilder(
                  _activeTrigger!,
                  suggestions[index],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
