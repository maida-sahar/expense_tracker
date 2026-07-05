// lib/widgets/adddialoge.dart

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:expense_tracker/models/transaction.dart';
import 'package:expense_tracker/widgets/category_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class AddDialog extends StatefulWidget {
  /// Pass when editing an existing transaction
  final String? editId;
  final Transaction? existing;

  const AddDialog({super.key, this.editId, this.existing});

  @override
  State<AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<AddDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeIn;

  late TransactionType _selectedType;
  late String _categoryId;
  late DateTime _date;
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  bool _submitting = false;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.editId != null;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();

    final t = widget.existing;
    _selectedType = t?.type ?? TransactionType.expense;
    _categoryId = t?.categoryId ??
        Categories.forType(_selectedType == TransactionType.income).first.id;
    _date = t?.date ?? DateTime.now();
    _titleController = TextEditingController(text: t?.title ?? '');
    _amountController = TextEditingController(
        text: t != null ? t.amount.toStringAsFixed(2) : '');
    _noteController = TextEditingController(text: t?.note ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _switchType(TransactionType type) {
    setState(() {
      _selectedType = type;
      // Reset category to first of the new type's list so we never keep a
      // mismatched category selected (e.g. "Salary" under Expense).
      _categoryId = Categories.forType(type == TransactionType.income).first.id;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _date.hour,
            _date.minute,
          ));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    final notifier = context.read<TransactionNotifier>();
    final uid = context.read<AuthNotifier>().user?.uid;

    if (uid == null) {
      setState(() => _submitting = false);
      return;
    }

    final txn = Transaction(
      id: widget.editId,
      userId: uid,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      type: _selectedType,
      date: _date,
      categoryId: _categoryId,
      note: _noteController.text.trim(),
    );

    try {
      if (_isEditing) {
        await notifier.updateTransaction(txn);
      } else {
        await notifier.addTransaction(txn);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencySymbol = context.watch<SettingsNotifier>().currency.symbol;
    final isIncome = _selectedType == TransactionType.income;

    return FadeTransition(
      opacity: _fadeIn,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _isEditing ? Icons.edit_rounded : Icons.add_rounded,
                          color: colors.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing ? 'Edit Transaction' : 'New Transaction',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Type toggle
                  Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _TypeButton(
                          label: 'Income',
                          icon: Icons.arrow_downward_rounded,
                          selected: isIncome,
                          selectedColor: const Color(0xFF22C55E),
                          onTap: () => _switchType(TransactionType.income),
                        ),
                        _TypeButton(
                          label: 'Expense',
                          icon: Icons.arrow_upward_rounded,
                          selected: !isIncome,
                          selectedColor: colors.error,
                          onTap: () => _switchType(TransactionType.expense),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Category picker
                  Text('Category',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          )),
                  const SizedBox(height: 8),
                  CategoryPicker(
                    isIncome: isIncome,
                    selectedId: _categoryId,
                    onSelected: (id) => setState(() => _categoryId = id),
                  ),

                  const SizedBox(height: 14),

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter a title'
                        : null,
                  ),

                  const SizedBox(height: 14),

                  // Amount field
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Text(currencySymbol,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter an amount';
                      }
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Date picker
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_date)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Note field
                  TextFormField(
                    controller: _noteController,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Note (optional)',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Submit button
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Add Transaction',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
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

// ── Type Toggle Button ────────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
