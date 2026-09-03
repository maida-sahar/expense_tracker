// lib/views/main_shell.dart

import 'package:expense_tracker/views/Home.dart';
import 'package:expense_tracker/views/analytics_view.dart';
import 'package:expense_tracker/views/settings_view.dart';
import 'package:expense_tracker/views/transaction_list.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static final _pages = [
    const HomePage(),
    const Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: _TransactionsHeader(),
      ),
      body: TransactionList(),
    ),
    const AnalyticsView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: colors.surface,
        indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.18),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded, color: Color(0xFF10B981)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
            label: 'Transactions',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: Icon(Icons.pie_chart_rounded, color: Color(0xFF10B981)),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: Color(0xFF10B981)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('All Transactions', style: TextStyle(fontWeight: FontWeight.w700)),
      automaticallyImplyLeading: false,
    );
  }
}

