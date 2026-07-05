// lib/widgets/summary_footer.dart
//
// The "hero" card at the top of Home — balance, budget progress ring, and
// income/expense stat chips. Named summary_footer.dart to match the
// project's existing file layout even though it now renders at the top.

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:expense_tracker/views/budget_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SummaryFooter extends StatelessWidget {
  const SummaryFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradient;
    final name = context.watch<AuthNotifier>().user?.displayName;
    final greetingName = (name == null || name.trim().isEmpty)
        ? ''
        : ', ${name.trim().split(' ').first}';

    return Consumer2<TransactionNotifier, SettingsNotifier>(
      builder: (_, notifier, settings, __) {
        final symbol = settings.currency.symbol;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(0.35),
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
                  Expanded(
                    child: Text(
                      'Hello$greetingName 👋',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const BudgetSheet(),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('Total balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 2),
              Text(
                formatMoney(symbol, notifier.balance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 18),

              // Budget progress
              if (notifier.monthlyBudget > 0) _BudgetBar(symbol: symbol, notifier: notifier),
              if (notifier.monthlyBudget > 0) const SizedBox(height: 16),

              Row(
                children: [
                  _StatCard(
                    label: 'Income',
                    value: notifier.totalIncome,
                    symbol: symbol,
                    icon: Icons.arrow_downward_rounded,
                    accentColor: const Color(0xFF4ADE80),
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: 'Expense',
                    value: notifier.totalExpense,
                    symbol: symbol,
                    icon: Icons.arrow_upward_rounded,
                    accentColor: const Color(0xFFFB7185),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetBar extends StatelessWidget {
  final String symbol;
  final TransactionNotifier notifier;

  const _BudgetBar({required this.symbol, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final over = notifier.budgetRemaining < 0;
    final progressColor = over
        ? const Color(0xFFFB7185)
        : (notifier.budgetProgress > 0.85 ? AppColors.budgetWarn : Colors.white);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFFB020), size: 16),
              const SizedBox(width: 6),
              const Text('Monthly Budget',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${formatMoney(symbol, notifier.expenseThisMonth)} / ${formatMoney(symbol, notifier.monthlyBudget)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: notifier.budgetProgress.toDouble(),
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 6),
            Text(
              'Over budget by ${formatMoney(symbol, notifier.budgetRemaining.abs())}',
              style: const TextStyle(
                  color: Color(0xFFFECACA), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double value;
  final String symbol;
  final IconData icon;
  final Color accentColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.symbol,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(icon, color: accentColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatMoney(symbol, value),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
