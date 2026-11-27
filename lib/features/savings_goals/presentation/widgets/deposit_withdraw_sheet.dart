import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/currency/currency_context_extension.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/presentation/components/money_input_field.dart';
import '../../../../core/theme/app_spacing.dart';
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
    final isDeposit = widget.isDeposit;

    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, accState) {
        final accounts = accState is AccountsLoaded ? accState.accounts : <Account>[];

        if (_selectedAccountId == null && accounts.isNotEmpty) {
          _selectedAccountId = accounts.first.id;
        }

        return AppBottomSheet(
          title: isDeposit
              ? 'Deposit to ${widget.goal.name}'
              : 'Withdraw from ${widget.goal.name}',
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Account Selector
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  decoration: InputDecoration(
                    labelText: isDeposit ? 'From Account' : 'To Account',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: accounts
                      .map(
                        (a) => DropdownMenuItem(
                          value: a.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Color(a.color).withAlpha(40),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 14,
                                  color: Color(a.color),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${a.name} (${context.formatMoney(a.currentBalance)})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAccountId = val);
                  },
                  validator: (val) => val == null ? 'Please select an account' : null,
                ),
                const SizedBox(height: AppSpacing.lg),

                // Amount
                MoneyInputField(
                  controller: _amountController,
                  autofocus: true,
                  label: 'Amount',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Note
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    hintText: 'e.g. Monthly contribution / milestone reward',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                FilledButton(
                  onPressed: () => _submit(accounts),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isDeposit ? 'Deposit' : 'Withdraw',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
