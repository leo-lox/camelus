import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../providers/theme_provider.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeColor = ref.watch(themeColorProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Theme Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // Theme Mode Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Theme Mode',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          ListTile(
            title: Text(
              'Light',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.sun(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeMode == ThemeMode.light
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              'Dark',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.moon(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeMode == ThemeMode.dark
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          ListTile(
            title: Text(
              'System',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            leading: Icon(
              PhosphorIcons.circleHalf(),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            trailing: themeMode == ThemeMode.system
                ? Icon(
                    PhosphorIcons.check(),
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            onTap: () {
              ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
            },
            tileColor: Theme.of(context).colorScheme.surface,
          ),

          Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 32),

          // Theme Color Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Theme Color',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _ColorOption(
                  color: Colors.blue,
                  label: 'Blue',
                  isSelected: themeColor == Colors.blue,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.blue);
                  },
                ),
                _ColorOption(
                  color: Colors.purple,
                  label: 'Purple',
                  isSelected: themeColor == Colors.purple,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.purple);
                  },
                ),
                _ColorOption(
                  color: Colors.green,
                  label: 'Green',
                  isSelected: themeColor == Colors.green,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.green);
                  },
                ),
                _ColorOption(
                  color: Colors.orange,
                  label: 'Orange',
                  isSelected: themeColor == Colors.orange,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.orange);
                  },
                ),
                _ColorOption(
                  color: Colors.red,
                  label: 'Red',
                  isSelected: themeColor == Colors.red,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.red);
                  },
                ),
                _ColorOption(
                  color: Colors.teal,
                  label: 'Teal',
                  isSelected: themeColor == Colors.teal,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.teal);
                  },
                ),
                _ColorOption(
                  color: Colors.pink,
                  label: 'Pink',
                  isSelected: themeColor == Colors.pink,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.pink);
                  },
                ),
                _ColorOption(
                  color: Colors.indigo,
                  label: 'Indigo',
                  isSelected: themeColor == Colors.indigo,
                  onTap: () {
                    ref.read(themeColorProvider.notifier).setThemeColor(Colors.indigo);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 3,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(
                    PhosphorIcons.check(PhosphorIconsStyle.bold),
                    color: Colors.white,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
