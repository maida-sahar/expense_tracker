// lib/views/analytics_view.dart

import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  String _timeframe = 'monthly'; // 'monthly' | 'yearly'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Analytics & Reports',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _TimeframeChip(
                                label: 'Monthly',
                                selected: _timeframe == 'monthly',
                                onTap: () => setState(() => _timeframe = 'monthly'),
                              ),
                              _TimeframeChip(
                                label: 'Yearly',
                                selected: _timeframe == 'yearly',
                                onTap: () => setState(() => _timeframe = 'yearly'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer2<TransactionNotifier, SettingsNotifier>(
              builder: (context, notifier, settings, _) {
                final symbol = settings.currency.symbol;
                final byCategory = notifier.expenseByCategory(timeframe: _timeframe);
                final trend = notifier.dailyNetTrend(days: 7);
                final paymentBreakdown = notifier.expenseByPaymentMethod();

                if (notifier.gettransaction.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.insights_rounded, size: 54, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 16),
                          Text(
                            'No financial records found',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Add your income and expenses to view detailed graphs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Identify Highest Spending Category
                MapEntry<String, double>? topCategory;
                if (byCategory.isNotEmpty) {
                  final sorted = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                  topCategory = sorted.first;
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Highest Spending Category Card
                      if (topCategory != null) ...[
                        _TopSpendingCard(
                          categoryId: topCategory.key,
                          amount: topCategory.value,
                          symbol: symbol,
                          notifier: notifier,
                        ),
                        const SizedBox(height: 20),
                      ],

                      Text(
                        'Category Breakdown (${_timeframe == 'monthly' ? 'This Month' : 'This Year'})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),

                      if (byCategory.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No expenses recorded for this timeframe.',
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                            ),
                          ),
                        )
                      else
                        _CategoryPieChart(byCategory: byCategory, symbol: symbol, notifier: notifier),

                      const SizedBox(height: 24),

                      Text(
                        'Last 7 Days Net Trend',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 14),
                      _WeeklyTrendChart(trend: trend),

                      const SizedBox(height: 24),

                      if (paymentBreakdown.isNotEmpty) ...[
                        Text(
                          'Payment Method Spending',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 14),
                        _PaymentMethodBreakdown(breakdown: paymentBreakdown, symbol: symbol),
                      ],

                      const SizedBox(height: 30),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeframeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeframeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF0F3D35) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TopSpendingCard extends StatelessWidget {
  final String categoryId;
  final double amount;
  final String symbol;
  final TransactionNotifier notifier;

  const _TopSpendingCard({
    required this.categoryId,
    required this.amount,
    required this.symbol,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final cat = notifier.categoryById(categoryId, false);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cat.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cat.color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cat.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(cat.icon, color: cat.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Highest Spending Category',
                  style: TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  cat.label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Text(
            formatMoney(symbol, amount),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cat.color),
          ),
        ],
      ),
    );
  }
}

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> byCategory;
  final String symbol;
  final TransactionNotifier notifier;

  const _CategoryPieChart({
    required this.byCategory,
    required this.symbol,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final total = byCategory.values.fold(0.0, (acc, b) => acc + b);
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 32,
                  sections: entries.map((e) {
                    final cat = notifier.categoryById(e.key, false);
                    final pct = total == 0 ? 0.0 : (e.value / total) * 100;
                    return PieChartSectionData(
                      color: cat.color,
                      value: e.value,
                      radius: 26,
                      title: pct >= 8 ? '${pct.toStringAsFixed(0)}%' : '',
                      titleStyle: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: entries.take(5).map((e) {
                  final cat = notifier.categoryById(e.key, false);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: cat.color, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(cat.label,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(formatMoney(symbol, e.value),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyTrendChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> trend;

  const _WeeklyTrendChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final maxAbs = trend
        .map((e) => e.value.abs())
        .fold(1.0, (acc, b) => acc > b ? acc : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
        child: SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAbs * 1.2,
              minY: -maxAbs * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= trend.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('E').format(trend[i].key),
                          style: TextStyle(fontSize: 10, color: colors.onSurfaceVariant),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: trend.asMap().entries.map((entry) {
                final i = entry.key;
                final value = entry.value.value;
                final positive = value >= 0;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      width: 18,
                      borderRadius: BorderRadius.circular(6),
                      color: positive ? const Color(0xFF10B981) : const Color(0xFFF97316),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaymentMethodBreakdown extends StatelessWidget {
  final Map<String, double> breakdown;
  final String symbol;

  const _PaymentMethodBreakdown({required this.breakdown, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final entries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: entries.map((e) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF10B981)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                  Text(
                    formatMoney(symbol, e.value),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

