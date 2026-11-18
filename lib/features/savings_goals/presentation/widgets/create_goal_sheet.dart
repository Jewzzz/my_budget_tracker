import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/presentation/components/money_input_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/savings_goals_cubit.dart';

class CreateGoalSheet extends StatefulWidget {
  final SavingsGoal? existingGoal;

  const CreateGoalSheet({
    super.key,
    this.existingGoal,
  });

  @override
  State<CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _targetAmountController;

  DateTime? _selectedTargetDate;
  String _selectedIcon = 'savings';
  int _selectedColor = 0xFF10B981;

  static const List<String> availableIcons = [
    'savings',
    'flight',
    'home',
    'directions_car',
    'school',
    'computer',
    'favorite',
    'beach_access',
    'card_giftcard',
    'diamond',
  ];

  static const List<int> availableColors = [
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Purple
    0xFFF59E0B, // Amber
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
    0xFFEF4444, // Red
    0xFF64748B, // Slate
  ];

  @override
  void initState() {
    super.initState();
    final existing = widget.existingGoal;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _targetAmountController = TextEditingController(
      text: existing != null
          ? (existing.targetAmount.minorUnits / 100).toStringAsFixed(2)
          : '',
    );
    _selectedTargetDate = existing?.targetDate;
    _selectedIcon = existing?.icon ?? availableIcons.first;
    _selectedColor = existing?.color ?? availableColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedTargetDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() {
        _selectedTargetDate = picked;
      });
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'savings':
        return Icons.savings_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'computer':
        return Icons.computer_outlined;
      case 'favorite':
        return Icons.favorite_border;
      case 'beach_access':
        return Icons.beach_access_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'diamond':
        return Icons.diamond_outlined;
      default:
        return Icons.savings_outlined;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final parsed = double.tryParse(_targetAmountController.text.replaceAll(',', '')) ?? 0.0;
    final minorUnits = (parsed * 100).round();
    final targetAmount = Money(minorUnits);

    if (widget.existingGoal != null) {
      final updated = widget.existingGoal!.copyWith(
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        targetDate: _selectedTargetDate,
        clearTargetDate: _selectedTargetDate == null,
        icon: _selectedIcon,
        color: _selectedColor,
      );
      context.read<SavingsGoalsCubit>().updateGoal(updated);
    } else {
      final newGoal = SavingsGoal(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        savedAmount: Money.zero,
        targetDate: _selectedTargetDate,
        status: SavingsGoalStatus.inProgress,
        icon: _selectedIcon,
        color: _selectedColor,
        createdAt: DateTime.now().toUtc(),
      );
      context.read<SavingsGoalsCubit>().createGoal(newGoal);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingGoal != null;

    return AppBottomSheet(
      title: isEditing ? 'Edit Savings Goal' : 'Create Savings Goal',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Goal Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g. Vacation, Emergency Fund',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a goal title';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // Target Amount
            MoneyInputField(
              controller: _targetAmountController,
              label: 'Target Amount',
            ),
            const SizedBox(height: AppSpacing.lg),

            // Target Date (Optional)
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Target Date (Optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _selectedTargetDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => setState(() => _selectedTargetDate = null),
                        )
                      : const Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                  _selectedTargetDate != null
                      ? DateFormat.yMMMd().format(_selectedTargetDate!)
                      : 'No target deadline',
                  style: _selectedTargetDate == null
                      ? TextStyle(color: theme.colorScheme.onSurfaceVariant)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Icon Picker
            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: availableIcons.map((iconName) {
                final isSelected = _selectedIcon == iconName;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _selectedIcon = iconName),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      _getIconData(iconName),
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Color Picker
            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: availableColors.map((colorVal) {
                final isSelected = _selectedColor == colorVal;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => setState(() => _selectedColor = colorVal),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Action Button
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isEditing ? 'Save Changes' : 'Create Goal',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
