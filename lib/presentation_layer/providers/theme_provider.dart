import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_app_provider.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;

  ThemeNotifier(this.ref) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final appDb = ref.read(dbAppProvider);
    final savedTheme = await appDb.read('themeMode');

    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        default:
          state = ThemeMode.system;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final appDb = ref.read(dbAppProvider);

    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }

    await appDb.save(key: 'themeMode', value: themeString);
  }

  void toggleTheme() {
    if (state == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }
}

final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref);
});

class ThemeColorNotifier extends StateNotifier<Color> {
  final Ref ref;

  ThemeColorNotifier(this.ref) : super(Colors.blue) {
    _loadThemeColor();
  }

  Future<void> _loadThemeColor() async {
    final appDb = ref.read(dbAppProvider);
    final savedColor = await appDb.read('themeColor');

    if (savedColor != null) {
      state = _colorFromString(savedColor);
    }
  }

  Future<void> setThemeColor(Color color) async {
    state = color;
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: 'themeColor', value: _colorToString(color));
  }

  String _colorToString(Color color) {
    if (color == Colors.blue) return 'blue';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.green) return 'green';
    if (color == Colors.orange) return 'orange';
    if (color == Colors.red) return 'red';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.pink) return 'pink';
    if (color == Colors.indigo) return 'indigo';
    return 'blue';
  }

  Color _colorFromString(String colorString) {
    switch (colorString) {
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'pink':
        return Colors.pink;
      case 'indigo':
        return Colors.indigo;
      default:
        return Colors.blue;
    }
  }
}

final themeColorProvider = StateNotifierProvider<ThemeColorNotifier, Color>((ref) {
  return ThemeColorNotifier(ref);
});

enum ThemeType {
  camelus,
  nostr,
  custom,
  system,
}

class ThemeTypeNotifier extends StateNotifier<ThemeType> {
  final Ref ref;

  ThemeTypeNotifier(this.ref) : super(ThemeType.custom) {
    _loadThemeType();
  }

  Future<void> _loadThemeType() async {
    final appDb = ref.read(dbAppProvider);
    final savedType = await appDb.read('themeType');

    if (savedType != null) {
      state = _themeTypeFromString(savedType);
    }
  }

  Future<void> setThemeType(ThemeType type) async {
    state = type;
    final appDb = ref.read(dbAppProvider);
    await appDb.save(key: 'themeType', value: _themeTypeToString(type));
  }

  String _themeTypeToString(ThemeType type) {
    switch (type) {
      case ThemeType.camelus:
        return 'camelus';
      case ThemeType.nostr:
        return 'nostr';
      case ThemeType.custom:
        return 'custom';
      case ThemeType.system:
        return 'system';
    }
  }

  ThemeType _themeTypeFromString(String typeString) {
    switch (typeString) {
      case 'camelus':
        return ThemeType.camelus;
      case 'nostr':
        return ThemeType.nostr;
      case 'custom':
        return ThemeType.custom;
      case 'system':
        return ThemeType.system;
      default:
        return ThemeType.custom;
    }
  }
}

final themeTypeProvider = StateNotifierProvider<ThemeTypeNotifier, ThemeType>((ref) {
  return ThemeTypeNotifier(ref);
});
