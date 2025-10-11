import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Locale Provider
/// Manages app language/locale state
/// Supports English (en) and Chinese (zh)
/// 
/// Features:
/// - Persistent storage: Saves user's language preference
/// - Auto-detection: Can detect device language
/// - Easy switching: Toggle or set specific language
class LocaleProvider with ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale _locale = const Locale('en');

  LocaleProvider() {
    _loadLocale();
  }

  Locale get locale => _locale;

  /// Load saved locale from persistent storage
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);
      if (savedLocale != null) {
        _locale = Locale(savedLocale);
        notifyListeners();
      }
    } catch (e) {
      // Fallback to default locale if error
      _locale = const Locale('en');
    }
  }

  /// Set locale and save to persistent storage
  /// Supported locales: 'en' (English), 'zh' (Chinese)
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    notifyListeners();
    
    // Save to persistent storage
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Toggle between English and Chinese
  void toggleLocale() {
    if (_locale.languageCode == 'en') {
      setLocale(const Locale('zh'));
    } else {
      setLocale(const Locale('en'));
    }
  }

  /// Set locale from device language (auto-detect)
  /// Falls back to English if device language is not supported
  void setLocaleFromDevice(Locale deviceLocale) {
    final languageCode = deviceLocale.languageCode;
    if (languageCode == 'zh' || languageCode == 'en') {
      setLocale(Locale(languageCode));
    } else {
      // Fallback to English for unsupported languages
      setLocale(const Locale('en'));
    }
  }

  /// Check if current locale is English
  bool get isEnglish => _locale.languageCode == 'en';

  /// Check if current locale is Chinese
  bool get isChinese => _locale.languageCode == 'zh';

  /// Get locale display name
  String get localeDisplayName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  /// Get all supported locales
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];
}
