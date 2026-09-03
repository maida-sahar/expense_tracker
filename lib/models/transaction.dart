// lib/models/transaction.dart

enum TransactionType { income, expense }

const List<String> kPaymentMethods = [
  'Cash',
  'Credit Card',
  'Debit Card',
  'Bank Transfer',
  'E-Wallet / UPI',
  'Other',
];

class Transaction {
  final String? id; // Firestore document ID
  final String userId;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String categoryId;
  final String paymentMethod;
  final String note;

  Transaction({
    this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.paymentMethod = 'Cash',
    this.note = '',
    DateTime? date,
  }) : date = date ?? DateTime.now();

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  /// Serialize to Firestore map
  Map<String, dynamic> toMap() => {
        'userId': userId,
        'title': title,
        'amount': amount,
        'type': type.name, // 'income' | 'expense'
        'date': date.millisecondsSinceEpoch,
        'categoryId': categoryId,
        'paymentMethod': paymentMethod,
        'note': note,
      };

  /// Deserialize from Firestore DocumentSnapshot
  factory Transaction.fromMap(Map<String, dynamic> map, String docId) {
    return Transaction(
      id: docId,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? 'Untitled',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] == 'income'
          ? TransactionType.income
          : TransactionType.expense,
      date: DateTime.fromMillisecondsSinceEpoch(
          map['date'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      categoryId: map['categoryId'] as String? ??
          (map['type'] == 'income' ? 'other_income' : 'other_expense'),
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      note: map['note'] as String? ?? '',
    );
  }

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? categoryId,
    String? paymentMethod,
    String? note,
  }) {
    return Transaction(
      id: id,
      userId: userId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
    );
  }
}

