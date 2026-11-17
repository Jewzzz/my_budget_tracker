import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
    _amountController = TextEditingController(
      text: (txn.amount.minorUnits.abs() / 100).toStringAsFixed(2),
    );
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final minorUnits = (parsedAmount * 100).round();
    final amount = Money(minorUnits);

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
      date: _selectedDate,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );

    context.read<TransactionsCubit>().updateTransaction(updated);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txn = widget.transaction;

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
                      'Edit ${txn.type.name[0].toUpperCase()}${txn.type.name.substring(1)}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Amount Field
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    final parsed = double.tryParse(value.replaceAll(',', ''));
                    if (parsed == null || parsed <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Account Selection
                BlocBuilder<AccountsCubit, AccountsState>(
                  builder: (context, accState) {
                    final accounts = accState is AccountsLoaded ? accState.accounts : <Account>[];
                    return DropdownButtonFormField<String>(
                      initialValue: accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null,
                      decoration: InputDecoration(
                        labelText: txn.isTransfer ? 'Source Account' : 'Account',
                        border: const OutlineInputBorder(),
                      ),
                      items: accounts
                          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedAccountId = val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Destination Account if Transfer
                if (txn.isTransfer) ...[
                  BlocBuilder<AccountsCubit, AccountsState>(
                    builder: (context, accState) {
                      final accounts = accState is AccountsLoaded ? accState.accounts : <Account>[];
                      return DropdownButtonFormField<String>(
                        initialValue: accounts.any((a) => a.id == _selectedDestinationAccountId)
                            ? _selectedDestinationAccountId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Destination Account',
                          border: OutlineInputBorder(),
                        ),
                        items: accounts
                            .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDestinationAccountId = val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
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
                        initialValue: matchingCategories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: matchingCategories
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategoryId = val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
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
                const SizedBox(height: 16),

                // Note Field
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Save Changes Button
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
