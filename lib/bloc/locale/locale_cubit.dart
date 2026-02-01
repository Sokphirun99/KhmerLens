// bloc/locale/locale_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../utils/constants.dart';

/// Supported app languages
enum AppLanguage { km, en }

/// Locale cubit for managing app language
class LocaleCubit extends Cubit<LocaleState> {
  LocaleCubit() : super(const LocaleState()) {
    _loadLocale();
  }

  static const _localeKey = AppConstants.keyLanguage;

  /// Load saved locale preference
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_localeKey) ?? 'en';
      final language = AppLanguage.values.firstWhere(
        (e) => e.name == languageCode,
        orElse: () => AppLanguage.en,
      );
      emit(LocaleState(language: language, isLoaded: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load locale preference: $e');
      }
      emit(const LocaleState(language: AppLanguage.en, isLoaded: true));
    }
  }

  /// Set app language
  Future<void> setLanguage(AppLanguage language) async {
    emit(state.copyWith(language: language));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, language.name);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to save locale preference: $e');
      }
    }
  }

  /// Get Flutter Locale from AppLanguage
  Locale get locale {
    switch (state.language) {
      case AppLanguage.km:
        return const Locale('km');
      case AppLanguage.en:
        return const Locale('en');
    }
  }
}

/// Locale state
class LocaleState {
  final AppLanguage language;
  final bool isLoaded;

  const LocaleState({
    this.language = AppLanguage.en,
    this.isLoaded = false,
  });

  LocaleState copyWith({
    AppLanguage? language,
    bool? isLoaded,
  }) {
    return LocaleState(
      language: language ?? this.language,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocaleState &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          isLoaded == other.isLoaded;

  @override
  int get hashCode => language.hashCode ^ isLoaded.hashCode;
}
