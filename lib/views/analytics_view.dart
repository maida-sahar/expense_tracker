// lib/views/analytics_view.dart

import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/utils/currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradient;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 96,
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
              child: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(left: 20, bottom: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Analytics',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Consumer2<TransactionNotifier, SettingsNotifier>(
              builder: (_, notifier, settings, __) {
                final byCategory = notifier.expenseByCategory();
                final trend = notifier.dailyNetTrend(days: 7);

                if (notifier.gettransaction.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        'Add some transactions to see your analytics.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spending by category (this month)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                      const SizedBox(height: 16),
                      if (byCategory.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Center(
                            child: Text('No expenses recorded this month yet.',
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
                          ),
                        )
                      else
                        _CategoryPieChart(byCategory: byCategory, symbol: settings.currency.symbol),
                      const SizedBox(height: 28),
                      Text('Last 7 days (net)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                      const SizedBox(height: 16),
                      _WeeklyTrendChart(trend: trend),
                      const SizedBox(height: 20),
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

class _CategoryPieChart extends StatelessWidget {
  final Map<String, double> byCategory;
  final String symbol;

  const _CategoryPieChart({required this.byCategory, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final total = byCategory.values.fold(0.0, (a, b) => a + b);
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
                  centerSpaceRadius: 34,
                  sections: entries.map((e) {
                    final cat = Categories.byId(e.key, false);
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
                  final cat = Categories.byId(e.key, false);
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
        .fold(1.0, (a, b) => a > b ? a : b);

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
                      color: positive ? const Color(0xFF2ECC71) : const Color(0xFFFF6B6B),
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
