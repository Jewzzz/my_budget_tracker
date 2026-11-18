import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_input_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';

class QuickAddTransactionSheet extends StatefulWidget {
  final TransactionType initialType;

  const QuickAddTransactionSheet({
    super.key,
    this.initialType = TransactionType.expense,
  });

  @override
  State<QuickAddTransactionSheet> createState() => _QuickAddTransactionSheetState();
}

class _QuickAddTransactionSheetState extends State<QuickAddTransactionSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late TransactionType _currentType;
  String? _selectedAccountId;
  String? _selectedDestinationAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    final initialIndex = widget.initialType == TransactionType.income
        ? 1
        : (widget.initialType == TransactionType.transfer ? 2 : 0);
    _tabController = TabController(length: 3, vsync: this, initialIndex: initialIndex);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        if (_tabController.index == 0) {
          _currentType = TransactionType.expense;
        } else if (_tabController.index == 1) {
          _currentType = TransactionType.income;
        } else {
          _currentType = TransactionType.transfer;
        }
        _selectedCategoryId = null; // Reset category when switching type
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Color get _indicatorColor {
    switch (_currentType) {
      case TransactionType.expense:
        return AppColors.expense;
      case TransactionType.income:
        return AppColors.income;
      case TransactionType.transfer:
        return AppColors.transfer;
    }
  }

  void _submit(List<Account> accounts) {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    final minorUnits = (parsedAmount * 100).round();
    final amount = Money(minorUnits);

    if (_currentType == TransactionType.transfer) {
      if (_selectedAccountId == _selectedDestinationAccountId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Source and destination accounts must be distinct')),
        );
        return;
      }
      final source = accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
      if (source != null &&
          source.type != AccountType.creditCard &&
          source.currentBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected account has insufficient funds for this action.')),
        );
        return;
      }
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      accountId: _selectedAccountId!,
      type: _currentType,
      amount: amount,
      categoryId: _currentType == TransactionType.transfer ? null : _selectedCategoryId,
      destinationAccountId:
          _currentType == TransactionType.transfer ? _selectedDestinationAccountId : null,
      date: _selectedDate.toUtc(),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    context.read<TransactionsCubit>().createTransaction(transaction);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, accountsState) {
        final accounts = accountsState is AccountsLoaded ? accountsState.accounts : <Account>[];

        // Default source and destination
        if (_selectedAccountId == null && accounts.isNotEmpty) {
          _selectedAccountId = accounts.first.id;
        }
        if (_selectedDestinationAccountId == null && accounts.length > 1) {
          _selectedDestinationAccountId = accounts.firstWhere(
            (a) => a.id != _selectedAccountId,
            orElse: () => accounts.last,
          ).id;
        }

        return BlocBuilder<TransactionsCubit, TransactionsState>(
          builder: (context, transactionsState) {
            final allCategories = transactionsState is TransactionsLoaded
                ? transactionsState.categories
                : <Category>[];

            final filteredCategories = allCategories
                .where((c) =>
                    _currentType == TransactionType.expense ? c.isExpense : c.isIncome)
                .toList();

            final hasSelectedCategory =
                filteredCategories.any((c) => c.id == _selectedCategoryId);
            if (!hasSelectedCategory) {
              _selectedCategoryId =
                  filteredCategories.isNotEmpty ? filteredCategories.first.id : null;
            }

            return AppBottomSheet(
              title: 'Add Transaction',
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Expense / Income / Transfer Tabs
                    Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        indicator: BoxDecoration(
                          color: _indicatorColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.white,
                        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                        tabs: const [
                          Tab(text: 'Expense'),
                          Tab(text: 'Income'),
                          Tab(text: 'Transfer'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Amount Field with auto-focus
                    MoneyInputField(
                      controller: _amountController,
                      autofocus: true,
                      label: 'Amount',
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Source Account Selector
                    DropdownButtonFormField<String>(
                      value: _selectedAccountId,
                      decoration: InputDecoration(
                        labelText: _currentType == TransactionType.transfer
                            ? 'Source Account'
                            : 'Account',
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      items: accounts
                          .map(
                            (acc) => DropdownMenuItem(
                              value: acc.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Color(acc.color).withAlpha(40),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 14,
                                      color: Color(acc.color),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      '${acc.name} (${acc.currentBalance.format()})',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedAccountId = val;
                        });
                      },
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Please select an account';
                        }
                        return null;
                      },
                    ),

                    // Destination Account Selector (Transfer only)
                    if (_currentType == TransactionType.transfer) ...[
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        value: _selectedDestinationAccountId,
                        decoration: const InputDecoration(
                          labelText: 'Destination Account',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: accounts
                            .map(
                              (acc) => DropdownMenuItem(
                                value: acc.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Color(acc.color).withAlpha(40),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_outlined,
                                        size: 14,
                                        color: Color(acc.color),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        '${acc.name} (${acc.currentBalance.format()})',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDestinationAccountId = val;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please select a destination account';
                          }
                          if (val == _selectedAccountId) {
                            return 'Source and destination accounts must be distinct';
                          }
                          return null;
                        },
                      ),
                    ],

                    // Category Selector (Expense & Income only)
                    if (_currentType != TransactionType.transfer) ...[
                      const SizedBox(height: AppSpacing.lg),
                      DropdownButtonFormField<String>(
                        key: ValueKey('category-picker-$_selectedCategoryId'),
                        value: filteredCategories
                                .any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : (filteredCategories.isNotEmpty
                                ? filteredCategories.first.id
                                : null),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        items: filteredCategories
                            .map(
                              (cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CategoryIconBadge(
                                      iconName: cat.icon,
                                      color: Color(cat.color),
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        cat.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedCategoryId = val;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),

                    // Date & Note Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                            onPressed: _pickDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      controller: _noteController,
                      decoration: const InputDecoration(
                        labelText: 'Note (Optional)',
                        hintText: 'e.g. ATM withdrawal / savings transfer',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton(
                      onPressed: () => _submit(accounts),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Save Transaction', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
