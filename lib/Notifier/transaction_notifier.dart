// lib/Notifier/transaction_notifier.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker/models/transaction.dart' as model;
import 'package:flutter/material.dart';

class TransactionNotifier extends ChangeNotifier {
  final _col = FirebaseFirestore.instance.collection('transactions');
  final _budgetCol = FirebaseFirestore.instance.collection('budgets');

  StreamSubscription? _txnSub;
  StreamSubscription? _budgetSub;

  String? _userId;
  final List<model.Transaction> _transactions = [];
  bool _loading = false;
  double _monthlyBudget = 0;

  // ── Getters ────────────────────────────────────────────────────────────────

  List<model.Transaction> get gettransaction =>
      List.unmodifiable(_transactions);

  bool get isLoading => _loading;

  double get totalIncome => _transactions
      .where((t) => t.type == model.TransactionType.income)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == model.TransactionType.expense)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get balance => totalIncome - totalExpense;

  double get monthlyBudget => _monthlyBudget;

  /// Expenses within the current calendar month.
  double get expenseThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.type == model.TransactionType.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get budgetRemaining => _monthlyBudget - expenseThisMonth;

  double get budgetProgress =>
      _monthlyBudget <= 0 ? 0 : (expenseThisMonth / _monthlyBudget).clamp(0, 1);

  /// Sum of expenses grouped by categoryId — used by the analytics chart.
  Map<String, double> expenseByCategory({DateTime? month}) {
    final target = month ?? DateTime.now();
    final map = <String, double>{};
    for (final t in _transactions) {
      if (t.type != model.TransactionType.expense) continue;
      if (t.date.year != target.year || t.date.month != target.month) continue;
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount;
    }
    return map;
  }

  /// Net (income - expense) per day for the last [days] days — used for the
  /// analytics trend line.
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
          .fold(0.0, (sum, t) =>
              sum + (t.type == model.TransactionType.income ? t.amount : -t.amount));
      result.add(MapEntry(day, net));
    }
    return result;
  }

  // ── Firestore sync ─────────────────────────────────────────────────────────

  /// Call once the authenticated user is known (e.g. from AuthGate) to start
  /// listening to that user's transactions + budget.
  void bindUser(String? userId) {
    if (_userId == userId) return;
    _userId = userId;
    _txnSub?.cancel();
    _budgetSub?.cancel();
    _transactions.clear();
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
      _monthlyBudget = (doc.data()?['monthlyBudget'] as num?)?.toDouble() ?? 0;
      notifyListeners();
    });
  }

  Future<void> setMonthlyBudget(double amount) async {
    if (_userId == null) return;
    _monthlyBudget = amount;
    notifyListeners();
    await _budgetCol.doc(_userId).set({'monthlyBudget': amount});
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────

  Future<void> addTransaction(model.Transaction transaction) async {
    await _col.add(transaction.toMap());
    // Realtime listener will reconcile the local list.
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
    super.dispose();
  }
}
