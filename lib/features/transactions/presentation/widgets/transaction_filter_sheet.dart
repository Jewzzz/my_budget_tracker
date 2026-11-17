import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';

enum DateRangePreset { all, thisMonth, last30Days, custom }

class TransactionFilterSheet extends StatefulWidget {
  final TransactionFilter initialFilter;

  const TransactionFilterSheet({
    super.key,
    required this.initialFilter,
  });

  @override
  State<TransactionFilterSheet> createState() => _TransactionFilterSheetState();
}

class _TransactionFilterSheetState extends State<TransactionFilterSheet> {
  late DateRangePreset _selectedPreset;
  DateTime? _startDate;
  DateTime? _endDate;
  TransactionType? _selectedType;
  String? _selectedAccountId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedType = widget.initialFilter.type;
    _selectedAccountId = widget.initialFilter.accountId;
    _selectedCategoryId = widget.initialFilter.categoryId;

    final now = DateTime.now();
    if (_startDate == null && _endDate == null) {
      _selectedPreset = DateRangePreset.all;
    } else if (_isThisMonth(_startDate, _endDate, now)) {
      _selectedPreset = DateRangePreset.thisMonth;
    } else if (_isLast30Days(_startDate, _endDate, now)) {
      _selectedPreset = DateRangePreset.last30Days;
    } else {
      _selectedPreset = DateRangePreset.custom;
    }
  }

  bool _isThisMonth(DateTime? start, DateTime? end, DateTime now) {
    if (start == null || end == null) return false;
    final firstDay = DateTime(now.year, now.month, 1);
    return start.year == firstDay.year &&
        start.month == firstDay.month &&
        start.day == 1;
  }

  bool _isLast30Days(DateTime? start, DateTime? end, DateTime now) {
    if (start == null || end == null) return false;
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    return start.difference(thirtyDaysAgo).inDays.abs() <= 1;
  }

  void _onPresetSelected(DateRangePreset preset) async {
    final now = DateTime.now();
    setState(() {
      _selectedPreset = preset;
    });

    if (preset == DateRangePreset.all) {
      setState(() {
        _startDate = null;
        _endDate = null;
      });
    } else if (preset == DateRangePreset.thisMonth) {
      setState(() {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      });
    } else if (preset == DateRangePreset.last30Days) {
      setState(() {
        _startDate = DateTime(now.year, now.month, now.day - 30);
        _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      });
    } else if (preset == DateRangePreset.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: _startDate != null && _endDate != null
            ? DateTimeRange(start: _startDate!, end: _endDate!)
            : null,
      );
      if (picked != null) {
        setState(() {
          _startDate = picked.start;
          _endDate = DateTime(
            picked.end.year,
            picked.end.month,
            picked.end.day,
            23,
            59,
            59,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Transactions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Range Preset Chips
              Text(
                'Date Range',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Dates'),
                    selected: _selectedPreset == DateRangePreset.all,
                    onSelected: (_) => _onPresetSelected(DateRangePreset.all),
                  ),
                  ChoiceChip(
                    label: const Text('This Month'),
                    selected: _selectedPreset == DateRangePreset.thisMonth,
                    onSelected: (_) => _onPresetSelected(DateRangePreset.thisMonth),
                  ),
                  ChoiceChip(
                    label: const Text('Last 30 Days'),
                    selected: _selectedPreset == DateRangePreset.last30Days,
                    onSelected: (_) => _onPresetSelected(DateRangePreset.last30Days),
                  ),
                  ChoiceChip(
                    label: Text(
                      _selectedPreset == DateRangePreset.custom && _startDate != null && _endDate != null
                          ? '${DateFormat.MMMd().format(_startDate!)} - ${DateFormat.MMMd().format(_endDate!)}'
                          : 'Custom Range',
                    ),
                    selected: _selectedPreset == DateRangePreset.custom,
                    onSelected: (_) => _onPresetSelected(DateRangePreset.custom),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Transaction Type Chips
              Text(
                'Transaction Type',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All Types'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _selectedType == TransactionType.expense,
                    onSelected: (_) => setState(() => _selectedType = TransactionType.expense),
                  ),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _selectedType == TransactionType.income,
                    onSelected: (_) => setState(() => _selectedType = TransactionType.income),
                  ),
                  ChoiceChip(
                    label: const Text('Transfer'),
                    selected: _selectedType == TransactionType.transfer,
                    onSelected: (_) => setState(() => _selectedType = TransactionType.transfer),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Account Selector
              BlocBuilder<AccountsCubit, AccountsState>(
                builder: (context, accState) {
                  final accounts = accState is AccountsLoaded ? accState.accounts : [];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedAccountId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Accounts'),
                          ),
                          ...accounts.map(
                            (a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedAccountId = val),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Category Selector
              BlocBuilder<TransactionsCubit, TransactionsState>(
                builder: (context, transState) {
                  final categories = transState is TransactionsLoaded ? transState.categories : <Category>[];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: categories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<TransactionsCubit>().clearFilter();
                        Navigator.pop(context);
                      },
                      child: const Text('Reset All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final newFilter = widget.initialFilter.copyWith(
                          startDate: _startDate,
                          clearStartDate: _startDate == null,
                          endDate: _endDate,
                          clearEndDate: _endDate == null,
                          type: _selectedType,
                          clearType: _selectedType == null,
                          accountId: _selectedAccountId,
                          clearAccountId: _selectedAccountId == null,
                          categoryId: _selectedCategoryId,
                          clearCategoryId: _selectedCategoryId == null,
                        );
                        context.read<TransactionsCubit>().updateFilter(newFilter);
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
