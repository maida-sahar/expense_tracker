// lib/views/transaction_list.dart

import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:expense_tracker/widgets/adddialoge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

enum _FilterType { all, income, expense }
enum _SortType { newest, oldest, highestAmount, lowestAmount }

class TransactionList extends StatefulWidget {
  const TransactionList({super.key});

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _FilterType _filter = _FilterType.all;
  _SortType _sort = _SortType.newest;
  String? _selectedCategory;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showSortPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sort Transactions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                title: const Text('Date (Newest First)'),
                trailing: _sort == _SortType.newest ? const Icon(Icons.check_rounded, color: Color(0xFF10B981)) : null,
                onTap: () {
                  setState(() => _sort = _SortType.newest);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('Date (Oldest First)'),
                trailing: _sort == _SortType.oldest ? const Icon(Icons.check_rounded, color: Color(0xFF10B981)) : null,
                onTap: () {
                  setState(() => _sort = _SortType.oldest);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward_rounded),
                title: const Text('Amount (Highest First)'),
                trailing: _sort == _SortType.highestAmount ? const Icon(Icons.check_rounded, color: Color(0xFF10B981)) : null,
                onTap: () {
                  setState(() => _sort = _SortType.highestAmount);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward_rounded),
                title: const Text('Amount (Lowest First)'),
                trailing: _sort == _SortType.lowestAmount ? const Icon(Icons.check_rounded, color: Color(0xFF10B981)) : null,
                onTap: () {
                  setState(() => _sort = _SortType.lowestAmount);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        var txns = List<Transaction>.from(notifier.gettransaction);

        // Filter Type (Income / Expense)
        if (_filter == _FilterType.income) {
          txns = txns.where((t) => t.type == TransactionType.income).toList();
        } else if (_filter == _FilterType.expense) {
          txns = txns.where((t) => t.type == TransactionType.expense).toList();
        }

        // Category Filter
        if (_selectedCategory != null) {
          txns = txns.where((t) => t.categoryId == _selectedCategory).toList();
        }

        // Search Query
        if (_query.trim().isNotEmpty) {
          final q = _query.trim().toLowerCase();
          txns = txns
              .where((t) =>
                  t.title.toLowerCase().contains(q) ||
                  t.note.toLowerCase().contains(q) ||
                  t.paymentMethod.toLowerCase().contains(q))
              .toList();
        }

        // Sort
        switch (_sort) {
          case _SortType.newest:
            txns.sort((a, b) => b.date.compareTo(a.date));
            break;
          case _SortType.oldest:
            txns.sort((a, b) => a.date.compareTo(b.date));
            break;
          case _SortType.highestAmount:
            txns.sort((a, b) => b.amount.compareTo(a.amount));
            break;
          case _SortType.lowestAmount:
            txns.sort((a, b) => a.amount.compareTo(b.amount));
            break;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: _SearchAndFilterBar(
                controller: _searchCtrl,
                filter: _filter,
                selectedCategory: _selectedCategory,
                onQueryChanged: (v) => setState(() => _query = v),
                onFilterChanged: (f) => setState(() => _filter = f),
                onCategoryChanged: (catId) => setState(() => _selectedCategory = catId),
                onOpenSort: () => _showSortPicker(context),
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

// ── Search + Filter Bar ────────────────────────────────────────────────────────

class _SearchAndFilterBar extends StatelessWidget {
  final TextEditingController controller;
  final _FilterType filter;
  final String? selectedCategory;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<_FilterType> onFilterChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onOpenSort;

  const _SearchAndFilterBar({
    required this.controller,
    required this.filter,
    required this.selectedCategory,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onCategoryChanged,
    required this.onOpenSort,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TransactionNotifier>();
    final isIncome = filter == _FilterType.income;
    final categories = notifier.allCategories(isIncome);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  hintText: 'Search transactions or notes',
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
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onOpenSort,
              icon: const Icon(Icons.sort_rounded),
              style: IconButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _FilterChip(
                label: 'All',
                selected: filter == _FilterType.all && selectedCategory == null,
                onTap: () {
                  onFilterChanged(_FilterType.all);
                  onCategoryChanged(null);
                },
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
              const SizedBox(width: 12),
              Container(width: 1, height: 20, color: Colors.grey.withValues(alpha: 0.3)),
              const SizedBox(width: 12),

              // Category filters
              ...categories.map((c) {
                final isSelected = selectedCategory == c.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      if (isSelected) {
                        onCategoryChanged(null);
                      } else {
                        onCategoryChanged(c.id);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? c.color.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isSelected ? c.color : Colors.transparent, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(c.icon, size: 14, color: isSelected ? c.color : Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            c.label,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? c.color : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
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

  const _FilterChip({required this.label, required this.selected, required this.onTap});

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

// ── Grouped List (by day) ──────────────────────────────────────────────────────

class _GroupedList extends StatelessWidget {
  final List<Transaction> transactions;

  const _GroupedList({required this.transactions});

  String _groupLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Today';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('EEEE, MMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.only(top: 14, bottom: 8, left: 4),
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

// ── Empty State ───────────────────────────────────────────────────────────────

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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, size: 40, color: colors.primary),
          ),
          const SizedBox(height: 18),
          Text('No transactions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  )),
          const SizedBox(height: 6),
          Text('Try searching or changing your filters',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  )),
        ],
      ),
    );
  }
}

// ── Transaction Card with Detail Sheet ─────────────────────────────────────────

class _TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final int index;

  const _TransactionCard({required this.transaction, required this.index});

  void _showDetailSheet(BuildContext context, Transaction txn) {
    final notifier = context.read<TransactionNotifier>();
    final category = notifier.categoryById(txn.categoryId, txn.isIncome);
    final currencySymbol = context.read<SettingsNotifier>().currency.symbol;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(category.icon, color: category.color, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.title,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                        ),
                        Text(
                          category.label,
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(currencySymbol, txn.isIncome ? txn.amount : -txn.amount, signed: true),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: txn.isIncome ? const Color(0xFF10B981) : const Color(0xFFF97316),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),

              _DetailRow(icon: Icons.calendar_today_rounded, label: 'Date & Time', value: DateFormat('EEEE, MMM d, yyyy · h:mm a').format(txn.date)),
              const SizedBox(height: 12),
              _DetailRow(icon: Icons.payment_rounded, label: 'Payment Method', value: txn.paymentMethod),
              if (txn.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.notes_rounded, label: 'Note', value: txn.note),
              ],

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context, txn);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      label: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openEdit(context, txn);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Edit Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
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
    final txn = transaction;
    final colors = Theme.of(context).colorScheme;
    final isIncome = txn.type == TransactionType.income;
    final category = context.watch<TransactionNotifier>().categoryById(txn.categoryId, isIncome);
    final currencySymbol = context.watch<SettingsNotifier>().currency.symbol;
    final accentColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFF97316);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(txn.id ?? txn.title + txn.date.toIso8601String()),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: Icon(Icons.delete_rounded, color: colors.onErrorContainer),
        ),
        confirmDismiss: (_) async {
          _confirmDelete(context, txn);
          return false;
        },
        child: Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showDetailSheet(context, txn),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: category.color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(category.icon, color: category.color, size: 22),
                  ),
                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          txn.title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              category.label,
                              style: TextStyle(fontSize: 11.5, color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(width: 6),
                            Container(width: 4, height: 4, decoration: BoxDecoration(color: colors.onSurfaceVariant, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Text(
                              txn.paymentMethod,
                              style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatMoney(currencySymbol, isIncome ? txn.amount : -txn.amount, signed: true),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: accentColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(txn.date),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      ],
    );
  }
}

