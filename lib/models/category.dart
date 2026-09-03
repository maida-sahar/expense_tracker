// lib/models/category.dart

import 'package:flutter/material.dart';

class TxnCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final bool isIncome;
  final bool isCustom;

  const TxnCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    this.isIncome = false,
    this.isCustom = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'iconCodePoint': icon.codePoint,
        'colorHex': color.toARGB32(),
        'isIncome': isIncome,
        'isCustom': true,
      };

  factory TxnCategory.fromMap(Map<String, dynamic> map, String docId) {
    final codePoint = map['iconCodePoint'] as int? ?? 0xe16c;
    final colorHex = map['colorHex'] as int? ?? 0xFF10B981;
    return TxnCategory(
      id: docId,
      label: map['label'] as String? ?? 'Custom',
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
      color: Color(colorHex),
      isIncome: map['isIncome'] as bool? ?? false,
      isCustom: true,
    );
  }
}

class Categories {
  Categories._();

  static const List<TxnCategory> defaultExpense = [
    TxnCategory(id: 'food', label: 'Food & Dining', icon: Icons.restaurant_rounded, color: Color(0xFFFF7A45)),
    TxnCategory(id: 'groceries', label: 'Groceries', icon: Icons.shopping_cart_rounded, color: Color(0xFF10B981)),
    TxnCategory(id: 'transport', label: 'Transport', icon: Icons.directions_car_filled_rounded, color: Color(0xFF3B82F6)),
    TxnCategory(id: 'shopping', label: 'Shopping', icon: Icons.shopping_bag_rounded, color: Color(0xFFA855F7)),
    TxnCategory(id: 'bills', label: 'Bills & Utilities', icon: Icons.receipt_long_rounded, color: Color(0xFFF59E0B)),
    TxnCategory(id: 'entertainment', label: 'Entertainment', icon: Icons.movie_filter_rounded, color: Color(0xFFEC4899)),
    TxnCategory(id: 'health', label: 'Health & Medical', icon: Icons.local_hospital_rounded, color: Color(0xFFEF4444)),
    TxnCategory(id: 'education', label: 'Education', icon: Icons.school_rounded, color: Color(0xFF06B6D4)),
    TxnCategory(id: 'rent', label: 'Housing & Rent', icon: Icons.home_rounded, color: Color(0xFF8B5CF6)),
    TxnCategory(id: 'travel', label: 'Travel', icon: Icons.flight_takeoff_rounded, color: Color(0xFF14B8A6)),
    TxnCategory(id: 'other_expense', label: 'Other Expense', icon: Icons.more_horiz_rounded, color: Color(0xFF64748B)),
  ];

  static const List<TxnCategory> defaultIncome = [
    TxnCategory(id: 'salary', label: 'Salary', icon: Icons.work_rounded, color: Color(0xFF10B981), isIncome: true),
    TxnCategory(id: 'freelance', label: 'Freelance', icon: Icons.laptop_mac_rounded, color: Color(0xFF0EA5E9), isIncome: true),
    TxnCategory(id: 'business', label: 'Business', icon: Icons.storefront_rounded, color: Color(0xFF8B5CF6), isIncome: true),
    TxnCategory(id: 'investment', label: 'Investment', icon: Icons.trending_up_rounded, color: Color(0xFF16A34A), isIncome: true),
    TxnCategory(id: 'gift', label: 'Gift', icon: Icons.card_giftcard_rounded, color: Color(0xFFF472B6), isIncome: true),
    TxnCategory(id: 'refund', label: 'Refund', icon: Icons.replay_rounded, color: Color(0xFF84CC16), isIncome: true),
    TxnCategory(id: 'other_income', label: 'Other Income', icon: Icons.more_horiz_rounded, color: Color(0xFF64748B), isIncome: true),
  ];

  static List<TxnCategory> forType(bool isIncome, {List<TxnCategory> customCategories = const []}) {
    final list = isIncome
        ? [...defaultIncome, ...customCategories.where((c) => c.isIncome)]
        : [...defaultExpense, ...customCategories.where((c) => !c.isIncome)];
    return list;
  }

  static TxnCategory byId(String id, bool isIncome, {List<TxnCategory> customCategories = const []}) {
    final list = forType(isIncome, customCategories: customCategories);
    return list.firstWhere(
      (c) => c.id == id,
      orElse: () => isIncome ? defaultIncome.last : defaultExpense.last,
    );
  }
}

