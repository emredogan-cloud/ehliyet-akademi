import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app theme mode (light / dark). The app launches in **DARK mode by default**
/// (premium dark-first design); the user can still switch to light and the choice persists
/// across launches via SharedPreferences.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'ea_theme_mode';

  @override
  ThemeMode build() {
    Future.microtask(_load);
    return ThemeMode.dark; // dark is the default experience
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_key)) {
        case 'light':
          state = ThemeMode.light;
        case 'dark':
          state = ThemeMode.dark;
        case 'system':
          state = ThemeMode.system;
        default:
          break; // no saved preference → keep the dark default
      }
    } catch (_) {
      // no prefs available (e.g. platform channel absent) → keep the dark default.
    }
  }

  Future<void> _save(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }

  void set(ThemeMode mode) {
    state = mode;
    _save(mode);
  }

  void toggle(Brightness platformBrightness) {
    final effectiveDark = state == ThemeMode.dark ||
        (state == ThemeMode.system && platformBrightness == Brightness.dark);
    final next = effectiveDark ? ThemeMode.light : ThemeMode.dark;
    state = next;
    _save(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
