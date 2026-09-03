// lib/widgets/adddialoge.dart

import 'package:expense_tracker/Notifier/auth_notifier.dart';
import 'package:expense_tracker/Notifier/settings_notifier.dart';
import 'package:expense_tracker/Notifier/transaction_notifier.dart';
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
  final TransactionType? initialType;

  const AddDialog({super.key, this.editId, this.existing, this.initialType});

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
  late String _paymentMethod;
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
    _selectedType = t?.type ?? widget.initialType ?? TransactionType.expense;
    _date = t?.date ?? DateTime.now();
    _paymentMethod = t?.paymentMethod ?? 'Cash';
    _titleController = TextEditingController(text: t?.title ?? '');
    _amountController = TextEditingController(
        text: t != null ? t.amount.toStringAsFixed(2) : '');
    _noteController = TextEditingController(text: t?.note ?? '');

    // Set initial category safely
    final notifier = context.read<TransactionNotifier>();
    final cats = notifier.allCategories(_selectedType == TransactionType.income);
    _categoryId = t?.categoryId ?? (cats.isNotEmpty ? cats.first.id : 'other_expense');
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
      final notifier = context.read<TransactionNotifier>();
      final cats = notifier.allCategories(type == TransactionType.income);
      if (cats.isNotEmpty) {
        _categoryId = cats.first.id;
      }
    });
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_date),
      );

      final time = pickedTime ?? TimeOfDay.fromDateTime(_date);
      setState(() => _date = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            time.hour,
            time.minute,
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
      paymentMethod: _paymentMethod,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                          color: isIncome
                              ? const Color(0xFF10B981).withValues(alpha: 0.18)
                              : const Color(0xFFF97316).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _isEditing
                              ? Icons.edit_rounded
                              : (isIncome ? Icons.south_west_rounded : Icons.north_east_rounded),
                          color: isIncome ? const Color(0xFF10B981) : const Color(0xFFF97316),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _isEditing
                            ? 'Edit Transaction'
                            : (isIncome ? 'Add Income' : 'Add Expense'),
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

                  const SizedBox(height: 18),

                  // Type toggle
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF0F1E1B)
                          : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        _TypeButton(
                          label: 'Expense',
                          icon: Icons.arrow_upward_rounded,
                          selected: !isIncome,
                          selectedColor: const Color(0xFFF97316),
                          onTap: () => _switchType(TransactionType.expense),
                        ),
                        _TypeButton(
                          label: 'Income',
                          icon: Icons.arrow_downward_rounded,
                          selected: isIncome,
                          selectedColor: const Color(0xFF10B981),
                          onTap: () => _switchType(TransactionType.income),
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
                      labelText: 'Title / Description',
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
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Enter an amount';
                      }
                      final parsed = double.tryParse(v.trim());
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  // Payment Method Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      prefixIcon: Icon(Icons.payment_rounded),
                    ),
                    items: kPaymentMethods.map((m) {
                      return DropdownMenuItem(value: m, child: Text(m));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),

                  const SizedBox(height: 14),

                  // Date & Time picker
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date & Time',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy · h:mm a').format(_date),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
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
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isIncome ? const Color(0xFF10B981) : const Color(0xFFF97316),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : (isIncome ? 'Add Income' : 'Add Expense'),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: selected ? Colors.white : Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: selected ? Colors.white : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

