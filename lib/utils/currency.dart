// lib/utils/currency.dart
//
// Small helper so widgets can format money without depending directly on
// SettingsNotifier's Currency type everywhere.

String formatMoney(String symbol, double value, {bool signed = false}) {
  final sign = signed && value > 0 ? '+' : (value < 0 ? '-' : '');
  return '$sign$symbol${value.abs().toStringAsFixed(2)}';
}
