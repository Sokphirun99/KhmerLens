// bloc/theme/theme_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';

/// Theme mode state
enum AppThemeMode { light, dark, system }

/// Theme cubit for managing app theme
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit() : super(const ThemeState()) {
    _loadTheme();
  }

  static const _themeKey = AppConstants.keyThemeMode;

  /// Load saved theme preference
  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString(_themeKey) ?? 'system';
      final mode = AppThemeMode.values.firstWhere(
        (e) => e.name == themeName,
        orElse: () => AppThemeMode.system,
      );
      emit(ThemeState(mode: mode, isLoaded: true));
    } catch (e) {
      // If SharedPreferences fails, use system theme as default
      if (kDebugMode) {
        debugPrint('Failed to load theme preference: $e');
      }
      emit(const ThemeState(mode: AppThemeMode.system, isLoaded: true));
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    emit(state.copyWith(mode: mode));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      // Theme is already updated in state, just log the error
      if (kDebugMode) {
        debugPrint('Failed to save theme preference: $e');
      }
    }
  }

  /// Toggle between light and dark (ignoring system)
  Future<void> toggleTheme() async {
    final newMode =
        state.mode == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Get Flutter ThemeMode from AppThemeMode
  ThemeMode get themeMode {
    switch (state.mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Theme state
class ThemeState {
  final AppThemeMode mode;
  final bool isLoaded;

  const ThemeState({
    this.mode = AppThemeMode.system,
    this.isLoaded = false,
  });

  ThemeState copyWith({
    AppThemeMode? mode,
    bool? isLoaded,
  }) {
    return ThemeState(
      mode: mode ?? this.mode,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeState &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          isLoaded == other.isLoaded;

  @override
  int get hashCode => mode.hashCode ^ isLoaded.hashCode;
}
