import 'package:camelus/config/palette.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(String) onSubmit;
  final Function(BuildContext) helpSearch;
  final FocusNode? externalFocusNode;
  final TextEditingController? externalController;
  final Widget? leading;
  final Widget? trailing;
  final Function? onBackPress;

  const SearchBarWidget({
    super.key,
    required this.onSearchChanged,
    required this.onSubmit,
    required this.helpSearch,
    this.externalFocusNode,
    this.externalController,
    this.leading,
    this.trailing,
    this.onBackPress,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    // Use external controller if provided, otherwise create a new one
    _searchController = widget.externalController ?? TextEditingController();

    // Use external focus node if provided, otherwise create a new one
    _searchFocusNode = widget.externalFocusNode ?? FocusNode();

    // Add listener to trigger rebuild when focus changes
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    // Only dispose internally created resources
    if (widget.externalController == null) {
      _searchController.dispose();
    }
    if (widget.externalFocusNode == null) {
      _searchFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 15, right: 10, bottom: 10),
      child: Row(
        children: [
          // back button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              //color: Paletter.getExtraDarkGray(context),
              borderRadius: BorderRadius.circular(200),
            ),
            child:
                widget.leading ??
                IconButton(
                  icon: _searchFocusNode.hasFocus
                      ? Icon(PhosphorIcons.arrowLeft())
                      : Icon(PhosphorIcons.magnifyingGlass(), size: 23),
                  color: Theme.of(context).colorScheme.onSurface,
                  onPressed: () {
                    _searchController.clear();
                    // unfocus search bar
                    _searchFocusNode.hasFocus
                        ? _searchFocusNode.unfocus()
                        : _searchFocusNode.requestFocus();
                    if (widget.onBackPress != null) {
                      widget.onBackPress!();
                    }
                  },
                ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                isDense: true,
                hintText: ' Search',
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 1.1,
                ),
                filled: true,
                fillColor: _searchFocusNode.hasFocus
                    ? Theme.of(context).colorScheme.surface
                    : Paletter.getExtraDarkGray(context),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                  borderSide: BorderSide(
                    color: Paletter.getExtraDarkGray(context),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.surface,
                  ),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              onChanged: (value) {
                widget.onSearchChanged(value);
              },
              onSubmitted: (value) {
                widget.onSubmit(value);
              },
              onTapOutside: (value) {
                // close keyboard
                //FocusScope.of(context).requestFocus(FocusNode());
              },
            ),
          ),
          const SizedBox(width: 5),
          if (widget.trailing == null)
            SizedBox(
              width: 41,
              height: 41,
              child: IconButton(
                icon: Icon(PhosphorIcons.question(), size: 23),
                color: Theme.of(context).colorScheme.onSurface,
                onPressed: () => widget.helpSearch(context),
              ),
            ),
          if (widget.trailing != null) widget.trailing!,
        ],
      ),
    );
  }
}
