// lib/views/budget_view.dart

import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:expense_tracker/views/budget_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  void _showSetCategoryBudgetDialog(BuildContext context, String categoryId, String categoryName, double currentBudget) {
    final ctrl = TextEditingController(text: currentBudget > 0 ? currentBudget.toStringAsFixed(0) : '');
    final symbol = context.read<SettingsNotifier>().currency.symbol;
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Budget for $categoryName', style: const TextStyle(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Monthly Limit',
              prefixIcon: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      final val = double.tryParse(ctrl.text.trim()) ?? 0.0;
                      setDialogState(() => saving = true);
                      await context.read<TransactionNotifier>().setCategoryBudget(categoryId, val);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Limit'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TransactionNotifier>();
    final symbol = context.watch<SettingsNotifier>().currency.symbol;
    final totalBudget = notifier.monthlyBudget;
    final totalSpent = notifier.expenseThisMonth;
    final remaining = notifier.budgetRemaining;
    final progress = notifier.budgetProgress;
    final isOver = remaining < 0;

    final categories = notifier.allCategories(false); // expense categories
    final expenseByCat = notifier.expenseByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & Financial Goals', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const BudgetSheet(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Monthly Budget Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3D35), Color(0xFF165C4F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flag_rounded, color: Color(0xFF34D399), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Monthly Expense Limit',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const BudgetSheet(),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Text('Edit Budget', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Spent', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            formatMoney(symbol, totalSpent),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Target Limit', style: TextStyle(color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(
                            formatMoney(symbol, totalBudget),
                            style: const TextStyle(color: Color(0xFF34D399), fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.toDouble(),
                      minHeight: 10,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isOver
                            ? const Color(0xFFEF4444)
                            : (progress > 0.85 ? const Color(0xFFF59E0B) : const Color(0xFF34D399)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% Used',
                        style: TextStyle(
                          color: isOver ? const Color(0xFFFECACA) : Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        isOver
                            ? 'Over budget by ${formatMoney(symbol, remaining.abs())}'
                            : '${formatMoney(symbol, remaining)} left',
                        style: TextStyle(
                          color: isOver ? const Color(0xFFFECACA) : const Color(0xFF34D399),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Category Budget Targets',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Set limits for specific categories to keep control over daily expenses.',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),

            // Category budget list
            ...categories.map((cat) {
              final spent = expenseByCat[cat.id] ?? 0.0;
              final catLimit = notifier.categoryBudgets[cat.id] ?? 0.0;
              final catProgress = catLimit <= 0 ? 0.0 : (spent / catLimit).clamp(0.0, 1.0);
              final catOver = catLimit > 0 && spent > catLimit;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: cat.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(cat.icon, color: cat.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(cat.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                Text(
                                  catLimit > 0
                                      ? '${formatMoney(symbol, spent)} of ${formatMoney(symbol, catLimit)}'
                                      : '${formatMoney(symbol, spent)} spent (No limit)',
                                  style: TextStyle(fontSize: 11.5, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.tune_rounded, size: 20),
                            onPressed: () => _showSetCategoryBudgetDialog(context, cat.id, cat.label, catLimit),
                          ),
                        ],
                      ),
                      if (catLimit > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: catProgress.toDouble(),
                            minHeight: 6,
                            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              catOver ? const Color(0xFFEF4444) : cat.color,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
