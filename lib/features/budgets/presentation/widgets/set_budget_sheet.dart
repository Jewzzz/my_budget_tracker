import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_input_field.dart';
import '../../../../core/theme/app_spacing.dart';
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

    return AppBottomSheet(
      title: isEditing ? 'Edit Category Budget' : 'Set Category Budget',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: available
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CategoryIconBadge(
                                iconName: c.icon,
                                color: Color(c.color),
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(c.name, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: isEditing
                      ? null // Cannot change category when editing existing budget
                      : (val) => setState(() => _selectedCategoryId = val),
                  validator: (val) => val == null ? 'Please select a category' : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Limit Amount Field
            MoneyInputField(
              controller: _amountController,
              autofocus: true,
              label: 'Monthly Spending Limit',
            ),
            const SizedBox(height: AppSpacing.xl),

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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Set Budget',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
