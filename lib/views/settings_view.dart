// lib/views/settings_view.dart

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/views/budget_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradient;
    final auth = context.watch<AuthNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final email = auth.user?.email ?? '';
    final name = auth.user?.displayName;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
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
                  padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            (name?.isNotEmpty == true ? name![0] : email.isNotEmpty ? email[0] : '?')
                                .toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (name?.isNotEmpty == true) ? name! : 'Your Account',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                email,
                                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel('Preferences'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Dark mode'),
                          subtitle: const Text('Switch between light and dark theme'),
                          value: settings.isDark,
                          onChanged: (v) => settings.toggleTheme(v),
                          secondary: const Icon(Icons.dark_mode_rounded),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.attach_money_rounded),
                          title: const Text('Currency'),
                          subtitle: Text('${settings.currency.label} (${settings.currency.symbol})'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _showCurrencyPicker(context, settings),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.flag_rounded),
                          title: const Text('Monthly budget'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const BudgetSheet(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel('Account'),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
                      title: Text('Sign out',
                          style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      onTap: () => _confirmSignOut(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text('Expense Tracker · v1.0',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text('You can sign back in anytime with your email and password.'),
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
              context.read<AuthNotifier>().signOut();
            },
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsNotifier settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Select currency',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              ...kSupportedCurrencies.map((c) => ListTile(
                    leading: Text(c.symbol, style: const TextStyle(fontSize: 18)),
                    title: Text(c.label),
                    trailing: c.code == settings.currency.code
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E))
                        : null,
                    onTap: () {
                      settings.setCurrency(c);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
