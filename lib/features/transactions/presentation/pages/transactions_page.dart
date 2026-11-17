import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/pages/categories_page.dart';
import '../../domain/entities/day_grouped_transactions.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/transaction_filter.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';
import '../widgets/transaction_details_sheet.dart';
import '../widgets/transaction_filter_sheet.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDayHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDay = DateTime(date.year, date.month, date.day);

    if (targetDay == today) {
      return 'Today • ${DateFormat.MMMd().format(date)}';
    } else if (targetDay == yesterday) {
      return 'Yesterday • ${DateFormat.MMMd().format(date)}';
    } else {
      return DateFormat.yMMMMd().format(date);
    }
  }

  void _openDetailsSheet(BuildContext context, Transaction txn) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountsCubit>()),
          BlocProvider.value(value: context.read<TransactionsCubit>()),
        ],
        child: TransactionDetailsSheet(transaction: txn),
      ),
    );
  }

  void _openFilterSheet(BuildContext context, TransactionFilter currentFilter) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountsCubit>()),
          BlocProvider.value(value: context.read<TransactionsCubit>()),
        ],
        child: TransactionFilterSheet(initialFilter: currentFilter),
      ),
    );
  }

  void _openCategoriesPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CategoriesCubit>(),
          child: const CategoriesPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, transState) {
        if (transState is TransactionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filter = transState is TransactionsLoaded
            ? transState.filter
            : const TransactionFilter();
        final groupedDays = transState is TransactionsLoaded
            ? transState.groupedTransactions
            : <DayGroupedTransactions>[];
        final categories = transState is TransactionsLoaded
            ? transState.categories
            : <Category>[];

        final isFiltering = _searchController.text.isNotEmpty || !filter.isEmpty;

        return BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, accState) {
            final accounts = accState is AccountsLoaded ? accState.accounts : [];

            return Column(
              children: [
                // Modern Top Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search notes or categories...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<TransactionsCubit>().updateSearchQuery('');
                                      setState(() {});
                                    },
                                  )
                                : null,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: 10,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
                            border: OutlineInputBorder(
                              borderRadius: AppRadius.mdBorder,
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            context.read<TransactionsCubit>().updateSearchQuery(val);
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Badge(
                        isLabelVisible: !filter.isEmpty,
                        backgroundColor: theme.colorScheme.primary,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.tune),
                          tooltip: 'Filters',
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.smBorder,
                            ),
                          ),
                          onPressed: () => _openFilterSheet(context, filter),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.category_outlined),
                        tooltip: 'Categories',
                        style: IconButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smBorder,
                          ),
                        ),
                        onPressed: () => _openCategoriesPage(context),
                      ),
                    ],
                  ),
                ),

                // Transactions List or Empty State
                Expanded(
                  child: groupedDays.isEmpty
                      ? AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Transactions Found',
                          message: isFiltering
                              ? 'Try adjusting your search query or filters.'
                              : 'Use the + button to quickly add your expenses and income.',
                          actionLabel: isFiltering ? 'Clear Filters' : null,
                          onAction: isFiltering
                              ? () {
                                  _searchController.clear();
                                  context.read<TransactionsCubit>().clearFilter();
                                  setState(() {});
                                }
                              : null,
                        )
                      : ListView.builder(
                          itemCount: groupedDays.length,
                          itemBuilder: (context, dayIndex) {
                            final dayGroup = groupedDays[dayIndex];
                            final isPositive = dayGroup.netTotal.isPositive;
                            final isNegative = dayGroup.netTotal.isNegative;
                            final netColor = isPositive
                                ? AppColors.income
                                : (isNegative
                                    ? AppColors.expense
                                    : theme.colorScheme.onSurfaceVariant);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Section Day Header with Date and Net Total Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.sm,
                                  ),
                                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(50),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDayHeader(dayGroup.date),
                                        style: theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: netColor.withAlpha(25),
                                          borderRadius: AppRadius.mdBorder,
                                          border: Border.all(color: netColor.withAlpha(50)),
                                        ),
                                        child: MoneyText(
                                          amount: dayGroup.netTotal,
                                          prefix: 'Net: ',
                                          showSign: true,
                                          autoColor: true,
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Day's Transactions
                                ...dayGroup.transactions.map((txn) {
                                  final cat = categories.where((c) => c.id == txn.categoryId).firstOrNull;
                                  final acc = accounts.where((a) => a.id == txn.accountId).firstOrNull;
                                  final dest = accounts.where((a) => a.id == txn.destinationAccountId).firstOrNull;

                                  final isTransfer = txn.isTransfer;
                                  final isIncome = txn.isIncome;
                                  final isExpense = txn.isExpense;

                                  final noteSuffix = txn.note != null && txn.note!.isNotEmpty
                                      ? ' • ${txn.note}'
                                      : '';

                                  final String iconName;
                                  final Color itemColor;
                                  final String titleText;
                                  final String subtitleText;

                                  if (isTransfer) {
                                    iconName = 'swap_horiz';
                                    itemColor = AppColors.transfer;
                                    titleText = 'Transfer';
                                    subtitleText =
                                        '${acc?.name ?? "Account"} → ${dest?.name ?? "Account"}$noteSuffix';
                                  } else {
                                    iconName = cat?.icon ?? 'category';
                                    itemColor = cat != null
                                        ? Color(cat.color)
                                        : theme.colorScheme.primary;
                                    titleText = cat?.name ?? 'Uncategorized';
                                    subtitleText = '${acc?.name ?? "Account"}$noteSuffix';
                                  }

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.xs,
                                        ),
                                        onTap: () => _openDetailsSheet(context, txn),
                                        leading: CategoryIconBadge(
                                          iconName: iconName,
                                          color: itemColor,
                                          size: CategoryBadgeSize.medium,
                                        ),
                                        title: Text(
                                          titleText,
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Text(
                                          subtitleText,
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        trailing: MoneyText(
                                          amount: isExpense ? -txn.amount : txn.amount,
                                          showSign: isIncome,
                                          autoColor: !isTransfer,
                                          color: isTransfer ? AppColors.transfer : null,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const Divider(height: 1, indent: 72),
                                    ],
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
