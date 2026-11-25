import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_input_field.dart';
import '../../../../core/temporal/date_normalizer.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/iso_currency.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';

class EditTransactionSheet extends StatefulWidget {
  final Transaction transaction;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionSheet> createState() => _EditTransactionSheetState();
}

class _EditTransactionSheetState extends State<EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late String _selectedAccountId;
  String? _selectedDestinationAccountId;
  String? _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final txn = widget.transaction;
    final iso = IsoCurrency.fromCode(txn.currencyCode);
    final decimals = iso.decimalDigits;
    final scale = iso.scaleFactor;
    final amountText = decimals == 0
        ? txn.amount.minorUnits.abs().toString()
        : (txn.amount.minorUnits.abs() / scale).toStringAsFixed(decimals);
    _amountController = TextEditingController(text: amountText);
    _noteController = TextEditingController(text: txn.note ?? '');
    _selectedAccountId = txn.accountId;
    _selectedDestinationAccountId = txn.destinationAccountId;
    _selectedCategoryId = txn.categoryId;
    _selectedDate = txn.date;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit(List<Account> accounts) {
    if (!_formKey.currentState!.validate()) return;

    final source = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    final accountCurrency = source?.currencyCode ?? widget.transaction.currencyCode;

    final minorUnits =
        MoneyInputField.parseMinorUnits(_amountController.text, accountCurrency) ?? 0;
    final amount = Money(minorUnits, accountCurrency);

    if (widget.transaction.isTransfer) {
      if (_selectedAccountId == _selectedDestinationAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be distinct')),
        );
        return;
      }
    }

    final updated = widget.transaction.copyWith(
      accountId: _selectedAccountId,
      destinationAccountId: widget.transaction.isTransfer ? _selectedDestinationAccountId : null,
      categoryId: !widget.transaction.isTransfer ? _selectedCategoryId : null,
      amount: amount,
      date: DateNormalizer.toUtcCalendarDate(_selectedDate),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    context.read<TransactionsCubit>().updateTransaction(updated);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final txn = widget.transaction;

    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, accState) {
        final accounts = accState is AccountsLoaded ? accState.accounts : <Account>[];
        final source = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
        final accountCurrency = source?.currencyCode ?? txn.currencyCode;

        return AppBottomSheet(
          title: 'Edit ${txn.type.name[0].toUpperCase()}${txn.type.name.substring(1)}',
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Amount Field
                MoneyInputField(
                  controller: _amountController,
                  currencyCode: accountCurrency,
                  label: 'Amount',
                ),
                const SizedBox(height: AppSpacing.lg),

                // Account Selection
                DropdownButtonFormField<String>(
                  value: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                  decoration: InputDecoration(
                    labelText: txn.isTransfer ? 'Source Account' : 'Account',
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
                                child: Text(a.name, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAccountId = val);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Destination Account if Transfer
                if (txn.isTransfer) ...[
                  DropdownButtonFormField<String>(
                    value: accounts.any((a) => a.id == _selectedDestinationAccountId)
                        ? _selectedDestinationAccountId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Destination Account',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                                  child: Text(a.name, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDestinationAccountId = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Category Selection if Expense or Income
                if (!txn.isTransfer) ...[
                  BlocBuilder<TransactionsCubit, TransactionsState>(
                    builder: (context, transState) {
                      final allCategories = transState is TransactionsLoaded ? transState.categories : <Category>[];
                      final matchingCategories = txn.isExpense
                          ? allCategories.where((c) => c.isExpense).toList()
                          : allCategories.where((c) => c.isIncome).toList();

                      return DropdownButtonFormField<String>(
                        value: matchingCategories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: matchingCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CategoryIconBadge(
                                      iconName: c.icon,
                                      color: Color(c.color),
                                      size: CategoryBadgeSize.small,
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
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategoryId = val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Date Picker
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(DateFormat.yMMMd().format(_selectedDate)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Save Changes Button
                FilledButton(
                  onPressed: () => _submit(accounts),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
