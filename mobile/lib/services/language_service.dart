import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  
  // Supported languages
  static const Map<String, Locale> supportedLanguages = {
    'English': Locale('en', 'US'),
    'हिंदी': Locale('hi', 'IN'),
    'Español': Locale('es', 'ES'),
    'Français': Locale('fr', 'FR'),
    'Deutsch': Locale('de', 'DE'),
  };

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('hi', 'IN'),
    Locale('es', 'ES'),
    Locale('fr', 'FR'),
    Locale('de', 'DE'),
  ];

  /// Get the currently selected language
  static Future<Locale> getCurrentLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final languageCode = prefs.getString(_languageKey);
      
      if (languageCode != null) {
        // Find the locale that matches the stored language code
        for (final locale in supportedLocales) {
          if (locale.languageCode == languageCode) {
            return locale;
          }
        }
      }
      
      // Default to English if no language is set or found
      return const Locale('en', 'US');
    } catch (e) {
      print('Error getting current language: $e');
      return const Locale('en', 'US');
    }
  }

  /// Set the selected language
  static Future<bool> setLanguage(Locale locale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_languageKey, locale.languageCode);
    } catch (e) {
      print('Error setting language: $e');
      return false;
    }
  }

  /// Get language name from locale
  static String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'hi':
        return 'हिंदी';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }

  /// Get locale from language name
  static Locale? getLocaleFromName(String languageName) {
    return supportedLanguages[languageName];
  }

  /// Check if a locale is supported
  static bool isLocaleSupported(Locale locale) {
    return supportedLocales.any((supportedLocale) => 
        supportedLocale.languageCode == locale.languageCode);
  }

  /// Get the device's default language if supported, otherwise English
  static Locale getDeviceLanguage() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    
    if (isLocaleSupported(deviceLocale)) {
      return deviceLocale;
    }
    
    return const Locale('en', 'US');
  }

  /// Reset language to device default
  static Future<bool> resetToDeviceLanguage() async {
    final deviceLanguage = getDeviceLanguage();
    return await setLanguage(deviceLanguage);
  }

  /// Get all supported language names
  static List<String> getSupportedLanguageNames() {
    return supportedLanguages.keys.toList();
  }

  /// Get language display info for UI
  static Map<String, dynamic> getLanguageDisplayInfo(Locale locale) {
    final languageName = getLanguageName(locale);
    return {
      'name': languageName,
      'nativeName': languageName,
      'code': locale.languageCode,
      'locale': locale,
    };
  }
}
