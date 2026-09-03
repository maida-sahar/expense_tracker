// lib/Notifier/settings_notifier.dart

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
  Currency('CAD', 'CA\$', 'Canadian Dollar'),
  Currency('AUD', 'A\$', 'Australian Dollar'),
];

class SettingsNotifier extends ChangeNotifier {
  static const _kThemeKey = 'theme_mode';
  static const _kCurrencyKey = 'currency_code';
  static const _kNotifKey = 'notifications_enabled';

  // Default to Dark Mode to match CashFlow Pro reference image design!
  ThemeMode _themeMode = ThemeMode.dark;
  Currency _currency = kSupportedCurrencies.first;
  bool _notificationsEnabled = true;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  Currency get currency => _currency;
  bool get isDark => _themeMode == ThemeMode.dark;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get loaded => _loaded;

  SettingsNotifier() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString(_kThemeKey);
    // If user hasn't explicitly chosen light, default to dark theme
    _themeMode = themeStr == 'light' ? ThemeMode.light : ThemeMode.dark;

    final code = prefs.getString(_kCurrencyKey);
    if (code != null) {
      _currency = kSupportedCurrencies.firstWhere(
        (c) => c.code == code,
        orElse: () => kSupportedCurrencies.first,
      );
    }

    _notificationsEnabled = prefs.getBool(_kNotifKey) ?? true;
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

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifKey, enabled);
  }
}

