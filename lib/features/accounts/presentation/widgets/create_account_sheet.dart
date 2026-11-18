import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/presentation/components/money_input_field.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/account.dart';
import '../cubit/accounts_cubit.dart';

class CreateAccountSheet extends StatefulWidget {
  const CreateAccountSheet({super.key});

  @override
  State<CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<CreateAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController(text: '0.00');

  AccountType _selectedType = AccountType.checking;
  String _selectedIcon = 'account_balance';
  int _selectedColor = 0xFF1E3A8A;

  static const List<Map<String, dynamic>> _iconOptions = [
    {'name': 'account_balance', 'icon': Icons.account_balance_outlined},
    {'name': 'savings', 'icon': Icons.savings_outlined},
    {'name': 'credit_card', 'icon': Icons.credit_card_outlined},
    {'name': 'payments', 'icon': Icons.payments_outlined},
    {'name': 'account_balance_wallet', 'icon': Icons.account_balance_wallet_outlined},
  ];

  static const List<int> _colorOptions = [
    0xFF1E3A8A, // Navy
    0xFF10B981, // Emerald
    0xFFEF4444, // Red
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFF06B6D4, // Cyan
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0.0;
    final minorUnits = (parsedAmount * 100).round();
    final balance = Money(minorUnits);

    final account = Account(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      initialBalance: balance,
      currentBalance: balance,
      isArchived: false,
      icon: _selectedIcon,
      color: _selectedColor,
      createdAt: DateTime.now().toUtc(),
    );

    context.read<AccountsCubit>().createAccount(account);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppBottomSheet(
      title: 'Create Account',
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Account Name',
                hintText: 'e.g. Main Checking, Cash Wallet',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an account name';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            DropdownButtonFormField<AccountType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Account Type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              items: AccountType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedType = val;
                  });
                }
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            MoneyInputField(
              controller: _balanceController,
              label: 'Initial Balance',
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _iconOptions.map((opt) {
                final isSelected = _selectedIcon == opt['name'];
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() {
                      _selectedIcon = opt['name'] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      opt['icon'] as IconData,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            Text('Color', style: theme.textTheme.labelLarge),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _colorOptions.map((colorVal) {
                final isSelected = _selectedColor == colorVal;
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    setState(() {
                      _selectedColor = colorVal;
                    });
                  },
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

            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Account', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
