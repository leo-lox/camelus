import 'package:camelus/config/palette.dart'; 
import 'package:flutter/material.dart';

/// Creates a custom long button widget.
/// 
/// This button is highly configurable with options for text, 
///  loading state and disabled state.
Widget longButton({
  required String name, 
  required Function() onPressed, // Callback function for button press.
  bool inverted = false, // If true, swaps the color scheme for the button.
  bool disabled = false, // If true, disables the button.
  bool loading = false, // If true, displays a loading indicator instead of text.
}) {
  return ElevatedButton(
    // Disable the button if `disabled` is true and not in a loading state.
    onPressed: disabled && !loading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      disabledBackgroundColor: Palette.darkGray,
      foregroundColor: inverted ? Palette.black : Palette.lightGray,
      backgroundColor: inverted ? Palette.extraLightGray : Palette.black,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), 
        side: const BorderSide(color: Palette.white, width: 1), 
      ),
    ),
    // Show a loading indicator if `loading` is true; otherwise, display text.
    child: loading
        ? _progress() // Widget to show a progress indicator.
        : Text(
            name, // Button text.
            style: TextStyle(
              color: inverted ? Palette.black : Palette.white, // Text color.
              fontSize: 18, // Font size for the text.
            ),
          ),
  );
}

/// Creates a loading indicator widget for the button.
/// 
/// This is a linear progress bar styled with colors defined in the `Palette`.
Widget _progress() {
  return const Padding(
    padding: EdgeInsets.only(left: 10, right: 10), 
    child: LinearProgressIndicator(
      backgroundColor: Palette.gray, 
      color: Palette.black, 
    ),
  );
}
