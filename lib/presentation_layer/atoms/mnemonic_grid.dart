import 'package:flutter/material.dart';
import '../../config/palette.dart';

class MnemonicSentenceGrid extends StatelessWidget {
  final List<String> words;

  final bool isVisible;

  const MnemonicSentenceGrid({
    super.key,
    required this.words,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      width: 500,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          mainAxisExtent: 50,
          childAspectRatio: 10 / 4,
          crossAxisSpacing: 0,
          mainAxisSpacing: 0,
        ),
        itemCount: words.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            child: Stack(
              children: [
                Center(
                  child: isVisible
                      ? Text(
                          words[index],
                          style: const TextStyle(fontSize: 16),
                        )
                      : const Text(
                          '••••',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                Positioned(
                  top: 2,
                  left: 4,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Palette.gray,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
