import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/savings_goals_cubit.dart';

class DepositWithdrawSheet extends StatefulWidget {
  final SavingsGoal goal;
  final bool isDeposit;

  const DepositWithdrawSheet({
    super.key,
    required this.goal,
    required this.isDeposit,
  });

  @override
  State<DepositWithdrawSheet> createState() => _DepositWithdrawSheetState();
}

class _DepositWithdrawSheetState extends State<DepositWithdrawSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _selectedAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit(List<Account> accounts) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    final parsed = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final minorUnits = (parsed * 100).round();
    final amount = Money(minorUnits);

    final selectedAccount = accounts.firstWhere((a) => a.id == _selectedAccountId);

    if (widget.isDeposit) {
      if (selectedAccount.type != AccountType.creditCard &&
          selectedAccount.currentBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected account has insufficient funds')),
        );
        return;
      }

      context.read<SavingsGoalsCubit>().deposit(
            goalId: widget.goal.id,
            accountId: _selectedAccountId!,
            amount: amount,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
    } else {
      if (widget.goal.savedAmount < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot withdraw more than accumulated savings')),
        );
        return;
      }

      context.read<SavingsGoalsCubit>().withdraw(
            goalId: widget.goal.id,
            accountId: _selectedAccountId!,
            amount: amount,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDeposit = widget.isDeposit;

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
                      isDeposit ? 'Deposit to Goal' : 'Withdraw from Goal',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(
                  widget.goal.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Account Selector
                BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, accState) {
                    final accounts = accState is AccountsLoaded ? accState.accounts : <Account>[];

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: isDeposit ? 'Funding Account' : 'Destination Account',
                        border: const OutlineInputBorder(),
                      ),
                      items: accounts
                          .map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text('${a.name} (${a.currentBalance.format()})'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                      validator: (val) => val == null ? 'Please select an account' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: const OutlineInputBorder(),
                    helperText: !isDeposit
                        ? 'Max withdrawable: ${widget.goal.savedAmount.format()}'
                        : null,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Amount must be greater than zero';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, accState) {
                    final accounts = accState is AccountsLoaded ? accState.accounts : <Account>[];
                    return FilledButton(
                      onPressed: () => _submit(accounts),
                      child: Text(isDeposit ? 'Deposit Funds' : 'Withdraw Funds'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
