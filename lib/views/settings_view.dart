// lib/views/settings_view.dart

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/theme/app_theme.dart';
import 'package:expense_tracker/views/budget_view.dart';
import 'package:expense_tracker/views/category_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _showEditNameDialog(BuildContext context, String currentName) {
    final nameCtrl = TextEditingController(text: currentName);
    bool saving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.w700)),
          content: TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline_rounded),
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
                      final newName = nameCtrl.text.trim();
                      if (newName.isEmpty) return;
                      setDialogState(() => saving = true);
                      await context.read<AuthNotifier>().user?.updateDisplayName(newName);
                      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppColors.heroGradientDark : AppColors.heroGradientLight;
    final auth = context.watch<AuthNotifier>();
    final settings = context.watch<SettingsNotifier>();
    final email = auth.user?.email ?? '';
    final name = auth.user?.displayName ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
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
                          radius: 30,
                          backgroundColor: const Color(0xFF10B981),
                          child: Text(
                            (name.isNotEmpty ? name[0] : email.isNotEmpty ? email[0] : '?').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      name.isNotEmpty ? name : 'My Account',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white70, size: 18),
                                    onPressed: () => _showEditNameDialog(context, name),
                                  ),
                                ],
                              ),
                              Text(
                                email,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5),
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
                  const _SectionLabel('App Preferences'),
                  Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Dark Theme'),
                          subtitle: const Text('CashFlow Pro dark emerald interface'),
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
                        SwitchListTile(
                          title: const Text('Financial Alerts & Warnings'),
                          subtitle: const Text('Notifications for budget limits & overspending'),
                          value: settings.notificationsEnabled,
                          onChanged: (v) => settings.toggleNotifications(v),
                          secondary: const Icon(Icons.notifications_active_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('Management & Customization'),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.category_rounded, color: Color(0xFF10B981)),
                          title: const Text('Custom Categories'),
                          subtitle: const Text('Create & manage custom expense/income categories'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CategoryManagerView()),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.flag_rounded, color: Color(0xFFF97316)),
                          title: const Text('Budget & Financial Goals'),
                          subtitle: const Text('Manage overall & category spending limits'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const BudgetView()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const _SectionLabel('Account'),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.logout_rounded, color: Theme.of(context).colorScheme.error),
                      title: Text(
                        'Sign Out',
                        style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _confirmSignOut(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'CashFlow Pro · v1.0.0',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete Professional Expense Tracker',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
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
        content: const Text('You can sign back in anytime with your credentials.'),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Select Currency', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              ...kSupportedCurrencies.map((c) => ListTile(
                    leading: Text(c.symbol, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    title: Text(c.label),
                    trailing: c.code == settings.currency.code
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
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

