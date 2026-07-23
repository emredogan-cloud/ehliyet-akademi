import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls the app theme mode (system / light / dark), mirroring the web's theme toggle.
/// Persisted across launches via SharedPreferences (Phase 2).
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'ea_theme_mode';

  @override
  ThemeMode build() {
    Future.microtask(_load);
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_key)) {
        case 'light':
          state = ThemeMode.light;
        case 'dark':
          state = ThemeMode.dark;
        default:
          break;
      }
    } catch (_) {
      // no prefs available (e.g. platform channel absent) → keep system default.
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
