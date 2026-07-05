// lib/views/transaction_list.dart

import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:expense_tracker/widgets/adddialoge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _FilterType { all, income, expense }

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _FilterType _filter = _FilterType.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionNotifier>(
      builder: (_, notifier, __) {
        if (notifier.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var txns = notifier.gettransaction;

        if (_filter == _FilterType.income) {
          txns = txns.where((t) => t.type == TransactionType.income).toList();
        } else if (_filter == _FilterType.expense) {
          txns = txns.where((t) => t.type == TransactionType.expense).toList();
        }
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          txns = txns
              .where((t) =>
                  t.title.toLowerCase().contains(q) ||
                  t.note.toLowerCase().contains(q))
              .toList();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _SearchAndFilterBar(
                controller: _searchCtrl,
                filter: _filter,
                onQueryChanged: (v) => setState(() => _query = v),
                onFilterChanged: (f) => setState(() => _filter = f),
              ),
            ),
            Expanded(
              child: txns.isEmpty
                  ? const _EmptyState()
                  : _GroupedList(transactions: txns),
            ),
          ],
        );
      },
    );
  }
}

// ── Search + filter bar ────────────────────────────────────────────────────────

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final _FilterType filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_FilterType> onFilterChanged;

  const _SearchAndFilterBar({
    required this.controller,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search transactions',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      controller.clear();
                      onQueryChanged('');
                    },
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All',
                selected: filter == _FilterType.all,
                onTap: () => onFilterChanged(_FilterType.all),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Income',
                selected: filter == _FilterType.income,
                onTap: () => onFilterChanged(_FilterType.income),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Expense',
                selected: filter == _FilterType.expense,
                onTap: () => onFilterChanged(_FilterType.expense),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ── Grouped list (by day) ──────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final List<Transaction> transactions;

  const _GroupedList({required this.transactions});

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Group consecutive-by-list transactions under a date header. The list is
    // already ordered by date (descending) from Firestore.
    final groups = <String, List<Transaction>>{};
    for (final t in transactions) {
      final label = _groupLabel(t.date);
      groups.putIfAbsent(label, () => []).add(t);
    }

    final entries = groups.entries.toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: entries.length,
      itemBuilder: (context, groupIndex) {
        final entry = entries[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8, left: 4),
              child: Text(
                entry.key,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            ...entry.value.asMap().entries.map(
              (e) => _TransactionCard(transaction: e.value, index: e.key),
            ),
          ],
        );
      },
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 44, color: colors.onPrimaryContainer),
          ),
          const SizedBox(height: 20),
          Text('No transactions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  )),
          const SizedBox(height: 6),
          Text('Tap + to add your first transaction',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

// ── Animated transaction card ─────────────────────────────────────────────────

class _TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final int index;

  const _TransactionCard({
    required this.transaction,
    required this.index,
  });

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 260 + widget.index * 30),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 35), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, Transaction txn) {
    final notifier = context.read<TransactionNotifier>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction'),
        content: Text('Delete "${txn.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              if (txn.id != null) notifier.deleteTransaction(txn.id!);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context, Transaction txn) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (_, __, ___) => AddDialog(editId: txn.id, existing: txn),
      transitionBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.transaction;
    final colors = Theme.of(context).colorScheme;
    final isIncome = txn.type == TransactionType.income;
    final category = Categories.byId(txn.categoryId, isIncome);
    final currencySymbol = context.watch<SettingsNotifier>().currency.symbol;

    final accentColor = isIncome ? const Color(0xFF22C55E) : colors.error;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Dismissible(
            key: ValueKey(txn.id ?? txn.title + txn.date.toIso8601String()),
            direction: DismissDirection.endToStart,
            background: _SwipeDeleteBackground(),
            confirmDismiss: (_) async {
              _confirmDelete(context, txn);
              return false; // we handle deletion ourselves
            },
            child: Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _openEdit(context, txn),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      // Category icon badge
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(category.icon, color: category.color, size: 22),
                      ),
                      const SizedBox(width: 14),

                      // Title + category + note
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              txn.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              txn.note.isNotEmpty ? txn.note : category.label,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Amount + type chip
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatMoney(currencySymbol, isIncome ? txn.amount : -txn.amount, signed: true),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: accentColor,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('h:mm a').format(txn.date),
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Swipe background ──────────────────────────────────────────────────────────

class _SwipeDeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: Icon(Icons.delete_rounded,
          color: Theme.of(context).colorScheme.onErrorContainer),
    );
  }
}
