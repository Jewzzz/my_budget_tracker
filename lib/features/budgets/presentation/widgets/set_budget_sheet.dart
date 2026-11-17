import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/cubit/categories_state.dart';
import '../../domain/entities/category_budget_overview.dart';
import '../cubit/budgets_cubit.dart';

class SetBudgetSheet extends StatefulWidget {
  final int year;
  final int month;
  final CategoryBudgetOverview? existingOverview;
  final List<String> existingBudgetCategoryIds;

  const SetBudgetSheet({
    super.key,
    required this.year,
    required this.month,
    this.existingOverview,
    this.existingBudgetCategoryIds = const [],
  });

  @override
  State<SetBudgetSheet> createState() => _SetBudgetSheetState();
}

class _SetBudgetSheetState extends State<SetBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingOverview;
    _amountController = TextEditingController(
      text: existing != null
          ? (existing.budget.limitAmount.minorUnits / 100).toStringAsFixed(2)
          : '',
    );
    _selectedCategoryId = existing?.category.id;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an expense category')),
      );
      return;
    }

    final parsed = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final minorUnits = (parsed * 100).round();
    final limitAmount = Money(minorUnits);

    context.read<BudgetsCubit>().setSpendingLimit(
          categoryId: _selectedCategoryId!,
          limitAmount: limitAmount,
          year: widget.year,
          month: widget.month,
        );

    Navigator.pop(context);
  }

  void _confirmDelete() {
    if (widget.existingOverview == null) return;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Budget?'),
        content: Text(
          'Are you sure you want to delete the budget for "${widget.existingOverview!.category.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<BudgetsCubit>().deleteBudget(widget.existingOverview!.budget.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingOverview != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? 'Edit Category Budget' : 'Set Category Budget',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category Selector
                BlocBuilder<CategoriesCubit, CategoriesState>(
                  builder: (context, catState) {
                    final categories = catState is CategoriesLoaded
                        ? catState.expenseCategories
                        : <Category>[];

                    // Available categories are unbudgeted ones, plus the currently selected one
                    final available = categories.where((c) {
                      if (c.id == _selectedCategoryId) return true;
                      return !widget.existingBudgetCategoryIds.contains(c.id);
                    }).toList();

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Expense Category',
                        border: OutlineInputBorder(),
                      ),
                      items: available
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                          .toList(),
                      onChanged: isEditing
                          ? null // Cannot change category when editing existing budget
                          : (val) => setState(() => _selectedCategoryId = val),
                      validator: (val) => val == null ? 'Please select a category' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Limit Amount Field
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Monthly Spending Limit',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a spending limit';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Spending limit must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    if (isEditing) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _confirmDelete,
                          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          label: Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        child: Text(isEditing ? 'Save Changes' : 'Set Budget'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
