// lib/views/category_manager.dart

import 'package:expense_tracker/Notifier/transaction_notifier.dart';
import 'package:expense_tracker/models/category.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CategoryManagerView extends StatefulWidget {
  const CategoryManagerView({super.key});

  @override
  State<CategoryManagerView> createState() => _CategoryManagerViewState();
}

class _CategoryManagerViewState extends State<CategoryManagerView> {
  bool _isIncome = false;

  void _showAddCategoryDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    IconData selectedIcon = Icons.category_rounded;
    Color selectedColor = const Color(0xFF10B981);
    bool dialogIsIncome = _isIncome;
    bool saving = false;

    final availableIcons = [
      Icons.shopping_cart_rounded,
      Icons.fastfood_rounded,
      Icons.card_giftcard_rounded,
      Icons.pets_rounded,
      Icons.fitness_center_rounded,
      Icons.subscriptions_rounded,
      Icons.child_care_rounded,
      Icons.construction_rounded,
      Icons.flight_takeoff_rounded,
      Icons.work_rounded,
      Icons.savings_rounded,
      Icons.monetization_on_rounded,
    ];

    final availableColors = [
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
      const Color(0xFFF97316),
      const Color(0xFFA855F7),
      const Color(0xFFEC4899),
      const Color(0xFFEF4444),
      const Color(0xFFF59E0B),
      const Color(0xFF06B6D4),
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('New Custom Category', style: TextStyle(fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Type toggle
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Expense'),
                          selected: !dialogIsIncome,
                          onSelected: (sel) {
                            if (sel) setDialogState(() => dialogIsIncome = false);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Income'),
                          selected: dialogIsIncome,
                          onSelected: (sel) {
                            if (sel) setDialogState(() => dialogIsIncome = true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: Icon(Icons.label_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Icon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableIcons.map((icon) {
                        final isSel = icon == selectedIcon;
                        return InkWell(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSel ? selectedColor.withValues(alpha: 0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSel ? selectedColor : Colors.grey.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Icon(icon, color: isSel ? selectedColor : Colors.grey, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text('Select Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableColors.map((color) {
                        final isSel = color == selectedColor;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
                          final name = titleCtrl.text.trim();
                          if (name.isEmpty) return;
                          setDialogState(() => saving = true);

                          final newCat = TxnCategory(
                            id: '',
                            label: name,
                            icon: selectedIcon,
                            color: selectedColor,
                            isIncome: dialogIsIncome,
                            isCustom: true,
                          );

                          await context.read<TransactionNotifier>().addCustomCategory(newCat);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<TransactionNotifier>();
    final categories = notifier.allCategories(_isIncome);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Manager', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Expense Categories')),
                    selected: !_isIncome,
                    onSelected: (sel) {
                      if (sel) setState(() => _isIncome = false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Income Categories')),
                    selected: _isIncome,
                    onSelected: (sel) {
                      if (sel) setState(() => _isIncome = true);
                    },
                  ),
                ),
              ],
            ),
          ),

          // Category List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final cat = categories[index];
                return Card(
                  child: ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 22),
                    ),
                    title: Text(
                      cat.label,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      cat.isCustom ? 'Custom Category' : 'Default Category',
                      style: TextStyle(
                        fontSize: 11,
                        color: cat.isCustom ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
                    trailing: cat.isCustom
                        ? IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () => notifier.deleteCustomCategory(cat.id),
                          )
                        : const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryDialog(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Category', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
