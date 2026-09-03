// lib/Notifier/transaction_notifier.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/transaction.dart' as model;
import 'package:flutter/material.dart';

class TransactionNotifier extends ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('transactions');
  final _budgetCol = FirebaseFirestore.instance.collection('budgets');
  final _categoryCol = FirebaseFirestore.instance.collection('custom_categories');

  StreamSubscription? _txnSub;
  StreamSubscription? _budgetSub;
  StreamSubscription? _categorySub;

  String? _userId;
  final List<model.Transaction> _transactions = [];
  final List<TxnCategory> _customCategories = [];
  Map<String, double> _categoryBudgets = {};
  bool _loading = false;
  double _monthlyBudget = 0;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<model.Transaction> get gettransaction =>
      List.unmodifiable(_transactions);

  List<TxnCategory> get customCategories =>
      List.unmodifiable(_customCategories);

  Map<String, double> get categoryBudgets =>
      Map.unmodifiable(_categoryBudgets);

  bool get isLoading => _loading;

  double get totalIncome => _transactions
      .where((t) => t.type == model.TransactionType.income)
      .fold(0.0, (acc, t) => acc + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == model.TransactionType.expense)
      .fold(0.0, (acc, t) => acc + t.amount);

  double get balance => totalIncome - totalExpense;

  double get monthlyBudget => _monthlyBudget;

  /// Income within current calendar month
  double get incomeThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == model.TransactionType.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  /// Expenses within the current calendar month.
  double get expenseThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == model.TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (acc, t) => acc + t.amount);
  }

  double get budgetRemaining => _monthlyBudget - expenseThisMonth;

  double get budgetProgress =>
      _monthlyBudget <= 0 ? 0 : (expenseThisMonth / _monthlyBudget).clamp(0, 1);

  /// Return all categories (default + user custom)
  List<TxnCategory> allCategories(bool isIncome) {
    return Categories.forType(isIncome, customCategories: _customCategories);
  }

  TxnCategory categoryById(String id, bool isIncome) {
    return Categories.byId(id, isIncome, customCategories: _customCategories);
  }

  /// Sum of expenses grouped by categoryId — for specified timeframe or current month
  Map<String, double> expenseByCategory({DateTime? month, String timeframe = 'monthly'}) {
    final target = month ?? DateTime.now();
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type != model.TransactionType.expense) continue;
      if (timeframe == 'monthly' && (t.date.year != target.year || t.date.month != target.month)) continue;
      if (timeframe == 'yearly' && t.date.year != target.year) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  /// Returns payment method spending breakdown
  Map<String, double> expenseByPaymentMethod() {
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type != model.TransactionType.expense) continue;
      map[t.paymentMethod] = (map[t.paymentMethod] ?? 0) + t.amount;
    }
    return map;
  }

  /// Dual-line curve data for Income vs Expense over 6 periods or days
  List<Map<String, dynamic>> incomeVsExpenseTrends({int months = 6}) {
    final now = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int i = months - 1; i >= 0; i--) {
      final monthDate = DateTime(now.year, now.month - i, 1);
      final inc = _transactions
          .where((t) =>
              t.type == model.TransactionType.income &&
              t.date.year == monthDate.year &&
              t.date.month == monthDate.month)
          .fold(0.0, (acc, t) => acc + t.amount);
      final exp = _transactions
          .where((t) =>
              t.type == model.TransactionType.expense &&
              t.date.year == monthDate.year &&
              t.date.month == monthDate.month)
          .fold(0.0, (acc, t) => acc + t.amount);
      result.add({
        'month': monthDate,
        'income': inc,
        'expense': exp,
      });
    }
    return result;
  }

  /// Net (income - expense) per day for the last [days] days
  List<MapEntry<DateTime, double>> dailyNetTrend({int days = 7}) {
    final now = DateTime.now();
    final result = <MapEntry<DateTime, double>>[];
    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final net = _transactions
          .where((t) =>
              t.date.year == day.year &&
              t.date.month == day.month &&
              t.date.day == day.day)
          .fold(0.0, (acc, t) =>
              acc + (t.type == model.TransactionType.income ? t.amount : -t.amount));
      result.add(MapEntry(day, net));
    }
    return result;
  }

  // ── Firestore sync ─────────────────────────────────────────────────────────

  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _txnSub?.cancel();
    _budgetSub?.cancel();
    _categorySub?.cancel();
    _transactions.clear();
    _customCategories.clear();
    _categoryBudgets.clear();
    _monthlyBudget = 0;

    if (userId == null) {
      _loading = false;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _txnSub = _col
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _transactions.clear();
      for (final doc in snapshot.docs) {
        _transactions.add(model.Transaction.fromMap(doc.data(), doc.id));
      }
      _transactions.sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
      notifyListeners();
    }, onError: (error) {
      _loading = false;
      notifyListeners();
      debugPrint('TransactionNotifier: transactions stream error -> $error');
    });

    _budgetSub = _budgetCol.doc(userId).snapshots().listen((doc) {
      final data = doc.data();
      _monthlyBudget = (data?['monthlyBudget'] as num?)?.toDouble() ?? 0;
      if (data?['categoryBudgets'] is Map) {
        final rawMap = data!['categoryBudgets'] as Map<String, dynamic>;
        _categoryBudgets = rawMap.map((k, v) => MapEntry(k, (v as num).toDouble()));
      } else {
        _categoryBudgets = {};
      }
      notifyListeners();
    });

    _categorySub = _categoryCol
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) {
      _customCategories.clear();
      for (final doc in snapshot.docs) {
        _customCategories.add(TxnCategory.fromMap(doc.data(), doc.id));
      }
      notifyListeners();
    });
  }

  Future<void> setMonthlyBudget(double amount) async {
    if (_userId == null) return;
    _monthlyBudget = amount;
    notifyListeners();
    await _budgetCol.doc(_userId).set({
      'monthlyBudget': amount,
      'categoryBudgets': _categoryBudgets,
    }, SetOptions(merge: true));
  }

  Future<void> setCategoryBudget(String categoryId, double amount) async {
    if (_userId == null) return;
    _categoryBudgets[categoryId] = amount;
    notifyListeners();
    await _budgetCol.doc(_userId).set({
      'monthlyBudget': _monthlyBudget,
      'categoryBudgets': _categoryBudgets,
    }, SetOptions(merge: true));
  }

  Future<void> addCustomCategory(TxnCategory category) async {
    if (_userId == null) return;
    final map = category.toMap()..['userId'] = _userId;
    await _categoryCol.add(map);
  }

  Future<void> deleteCustomCategory(String categoryId) async {
    await _categoryCol.doc(categoryId).delete();
  }

  // ── CRUD Transactions ───────────────────────────────────────────────────────

  Future<void> addTransaction(model.Transaction transaction) async {
    await _col.add(transaction.toMap());
  }

  Future<void> updateTransaction(model.Transaction updated) async {
    if (updated.id == null) return;
    await _col.doc(updated.id).update(updated.toMap());
  }

  Future<void> deleteTransaction(String id) async {
    await _col.doc(id).delete();
  }

  @override
  void dispose() {
    _txnSub?.cancel();
    _budgetSub?.cancel();
    _categorySub?.cancel();
    super.dispose();
  }
}

