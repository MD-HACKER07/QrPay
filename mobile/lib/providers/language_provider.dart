import 'package:flutter/material.dart';
import '../services/language_service.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('en', 'US');
  
  Locale get currentLocale => _currentLocale;
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  Future<void> _loadSavedLanguage() async {
    _currentLocale = await LanguageService.getCurrentLanguage();
    notifyListeners();
  }
  
  Future<void> changeLanguage(Locale locale) async {
    if (_currentLocale == locale) return;
    
    _currentLocale = locale;
    await LanguageService.setLanguage(locale);
    notifyListeners();
  }
  
  String getCurrentLanguageName() {
    return LanguageService.getLanguageName(_currentLocale);
  }
  
  List<String> getSupportedLanguages() {
    return LanguageService.getSupportedLanguageNames();
  }
  
  Locale? getLocaleFromName(String languageName) {
    return LanguageService.getLocaleFromName(languageName);
  }
}
