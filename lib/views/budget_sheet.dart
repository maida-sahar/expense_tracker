// lib/views/budget_sheet.dart

import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class BudgetSheet extends StatefulWidget {
  const BudgetSheet({super.key});

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final current = context.read<TransactionNotifier>().monthlyBudget;
    _ctrl = TextEditingController(
        text: current > 0 ? current.toStringAsFixed(0) : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_ctrl.text.trim()) ?? 0;
    setState(() => _saving = true);
    await context.read<TransactionNotifier>().setMonthlyBudget(value);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final symbol = context.watch<SettingsNotifier>().currency.symbol;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.flag_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Text('Set Monthly Budget',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Get warned when your spending gets close to this limit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                labelText: 'Budget amount',
                prefixIcon: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(symbol, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Budget',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
