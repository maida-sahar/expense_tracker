// lib/widgets/summary_footer.dart

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:expense_tracker/views/budget_sheet.dart';
import 'package:expense_tracker/widgets/adddialoge.dart';
import 'package:expense_tracker/widgets/cashflow_logo.dart';
import 'package:expense_tracker/widgets/income_expense_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SummaryFooter extends StatelessWidget {
  const SummaryFooter({super.key});

  void _openAddDialog(BuildContext context, {TransactionType? type}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) => AddDialog(initialType: type),
      transitionBuilder: (context, anim, secondaryAnimation, child) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight;
    final auth = context.watch<AuthNotifier>();
    final user = auth.user;
    final name = user?.displayName;
    final greetingName = (name == null || name.trim().isEmpty)
        ? ''
        : ', ${name.trim().split(' ').first}';

    return Consumer2<TransactionNotifier, SettingsNotifier>(
      builder: (context, notifier, settings, child) {
        final symbol = settings.currency.symbol;
        final trends = notifier.incomeVsExpenseTrends(months: 6);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.4),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top App Bar Header: CashFlow Pro + Search + Bell Alert + User Avatar
                Row(
                  children: [
                    const CashFlowLogo(size: 40, iconSize: 20),
                    const SizedBox(width: 12),
                    Text(
                      'CashFlow Pro',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                        ),
                        if (notifier.budgetProgress > 0.85)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF97316),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF10B981),
                      child: Text(
                        (name?.isNotEmpty == true
                                ? name![0]
                                : user?.email?.isNotEmpty == true
                                    ? user!.email![0]
                                    : 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Greeting & Total Balance
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back$greetingName 👋',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Total Balance',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(symbol, notifier.balance),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 28,
                              ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const BudgetSheet(),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.flag_rounded, color: Color(0xFF34D399), size: 16),
                            SizedBox(width: 6),
                            Text('Budget', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Stat chips (Income & Expense)
                Row(
                  children: [
                    _StatChip(
                      label: 'Income',
                      value: notifier.totalIncome,
                      symbol: symbol,
                      icon: Icons.arrow_downward_rounded,
                      accentColor: const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      label: 'Expenses',
                      value: notifier.totalExpense,
                      symbol: symbol,
                      icon: Icons.arrow_upward_rounded,
                      accentColor: const Color(0xFFF97316),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick Action Buttons (Quick Add Expense & Quick Add Income)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddDialog(context, type: TransactionType.income),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                        label: const Text('Quick Income', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddDialog(context, type: TransactionType.expense),
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFF97316), size: 18),
                        label: const Text('Quick Expense', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: const Color(0xFFF97316).withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Budget Warning Alert Banner (if budget is set & close to limit)
                if (notifier.monthlyBudget > 0)
                  _BudgetWarningBanner(symbol: symbol, notifier: notifier),

                if (notifier.monthlyBudget > 0) const SizedBox(height: 16),

                // Income vs Expenses Spline Chart
                IncomeExpenseChart(
                  data: trends,
                  currencySymbol: symbol,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BudgetWarningBanner extends StatelessWidget {
  final String symbol;
  final TransactionNotifier notifier;

  const _BudgetWarningBanner({required this.symbol, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final over = notifier.budgetRemaining < 0;
    final progress = notifier.budgetProgress;

    Color bannerColor = const Color(0xFF10B981);
    IconData icon = Icons.check_circle_outline_rounded;
    String message = 'Budget on track (${(progress * 100).toStringAsFixed(0)}% used)';

    if (over) {
      bannerColor = const Color(0xFFEF4444);
      icon = Icons.warning_amber_rounded;
      message = 'Over budget by ${formatMoney(symbol, notifier.budgetRemaining.abs())}!';
    } else if (progress > 0.85) {
      bannerColor = const Color(0xFFF59E0B);
      icon = Icons.error_outline_rounded;
      message = 'Near monthly budget limit (${(progress * 100).toStringAsFixed(0)}% used)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bannerColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bannerColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bannerColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: bannerColor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          InkWell(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const BudgetSheet(),
            ),
            child: Text(
              'Details',
              style: TextStyle(color: bannerColor, fontSize: 11.5, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final double value;
  final String symbol;
  final IconData icon;
  final Color accentColor;

  const _StatChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
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
                fontSize: 16,
                fontWeight: FontWeight.w800,
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

