// lib/models/category.dart
//
// Predefined transaction categories. Kept as a static in-app list (not a
// Firestore collection) since the set is small, fixed, and needs to render
// instantly with icons/colors in the picker — no extra reads required.

import 'package:flutter/material.dart';

class TxnCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const TxnCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class Categories {
  Categories._();

  static const List<TxnCategory> expense = [
    TxnCategory(id: 'food', label: 'Food & Drinks', icon: Icons.restaurant_rounded, color: Color(0xFFFF7A45)),
    TxnCategory(id: 'transport', label: 'Transport', icon: Icons.directions_car_filled_rounded, color: Color(0xFF3B82F6)),
    TxnCategory(id: 'shopping', label: 'Shopping', icon: Icons.shopping_bag_rounded, color: Color(0xFFA855F7)),
    TxnCategory(id: 'bills', label: 'Bills & Utilities', icon: Icons.receipt_long_rounded, color: Color(0xFFF59E0B)),
    TxnCategory(id: 'entertainment', label: 'Entertainment', icon: Icons.movie_filter_rounded, color: Color(0xFFEC4899)),
    TxnCategory(id: 'health', label: 'Health', icon: Icons.local_hospital_rounded, color: Color(0xFFEF4444)),
    TxnCategory(id: 'education', label: 'Education', icon: Icons.school_rounded, color: Color(0xFF06B6D4)),
    TxnCategory(id: 'home', label: 'Home & Rent', icon: Icons.home_rounded, color: Color(0xFF8B5CF6)),
    TxnCategory(id: 'travel', label: 'Travel', icon: Icons.flight_takeoff_rounded, color: Color(0xFF14B8A6)),
    TxnCategory(id: 'other_expense', label: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF64748B)),
  ];

  static const List<TxnCategory> income = [
    TxnCategory(id: 'salary', label: 'Salary', icon: Icons.work_rounded, color: Color(0xFF22C55E)),
    TxnCategory(id: 'freelance', label: 'Freelance', icon: Icons.laptop_mac_rounded, color: Color(0xFF0EA5E9)),
    TxnCategory(id: 'investment', label: 'Investment', icon: Icons.trending_up_rounded, color: Color(0xFF16A34A)),
    TxnCategory(id: 'gift', label: 'Gift', icon: Icons.card_giftcard_rounded, color: Color(0xFFF472B6)),
    TxnCategory(id: 'refund', label: 'Refund', icon: Icons.replay_rounded, color: Color(0xFF84CC16)),
    TxnCategory(id: 'other_income', label: 'Other', icon: Icons.more_horiz_rounded, color: Color(0xFF64748B)),
  ];

  static List<TxnCategory> forType(bool isIncome) => isIncome ? income : expense;

  static TxnCategory byId(String id, bool isIncome) {
    final list = forType(isIncome);
    return list.firstWhere(
      (c) => c.id == id,
      orElse: () => list.last,
    );
  }
}
