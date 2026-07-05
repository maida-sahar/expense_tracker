// lib/Notifier/settings_notifier.dart
//
// Persists theme mode + currency choice locally with shared_preferences.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Currency {
  final String code;
  final String symbol;
  final String label;
  const Currency(this.code, this.symbol, this.label);
}

const List<Currency> kSupportedCurrencies = [
  Currency('USD', '\$', 'US Dollar'),
  Currency('PKR', '₨', 'Pakistani Rupee'),
  Currency('EUR', '€', 'Euro'),
  Currency('GBP', '£', 'British Pound'),
  Currency('INR', '₹', 'Indian Rupee'),
  Currency('AED', 'د.إ', 'UAE Dirham'),
];

class SettingsNotifier extends ChangeNotifier {
  static const _kThemeKey = 'theme_mode';
  static const _kCurrencyKey = 'currency_code';

  ThemeMode _themeMode = ThemeMode.light;
  Currency _currency = kSupportedCurrencies.first;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  Currency get currency => _currency;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get loaded => _loaded;

  SettingsNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kThemeKey);
    _themeMode = themeStr == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final code = prefs.getString(_kCurrencyKey);
    if (code != null) {
      _currency = kSupportedCurrencies.firstWhere(
        (c) => c.code == code,
        orElse: () => kSupportedCurrencies.first,
      );
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool dark) async {
    _themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, dark ? 'dark' : 'light');
  }

  Future<void> setCurrency(Currency c) async {
    _currency = c;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, c.code);
  }
}
