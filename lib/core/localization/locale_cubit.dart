import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleCubit extends Cubit<Locale> {
  static const _langKey = 'selected_language';
  final SharedPreferences _prefs;

  LocaleCubit(this._prefs, [String? initialLangCode]) 
      : super(initialLangCode != null ? Locale(initialLangCode) : const Locale('en')) {
    if (initialLangCode == null) {
      _loadSavedLocale();
    }
  }

  void _loadSavedLocale() {
    final langCode = _prefs.getString(_langKey);
    if (langCode != null) {
      emit(Locale(langCode));
    }
  }

  Future<void> changeLanguage(String languageCode) async {
    await _prefs.setString(_langKey, languageCode);
    emit(Locale(languageCode));
  }

  void toggleLanguage() {
    final newCode = state.languageCode == 'en' ? 'ar' : 'en';
    changeLanguage(newCode);
  }
}
