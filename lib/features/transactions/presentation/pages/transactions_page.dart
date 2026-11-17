import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
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

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'work':
        return Icons.work_outlined;
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      default:
        return Icons.category_outlined;
    }
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

        final filter = transState is TransactionsLoaded ? transState.filter : const TransactionFilter();
        final groupedDays = transState is TransactionsLoaded
            ? transState.groupedTransactions
            : <DayGroupedTransactions>[];
        final categories = transState is TransactionsLoaded ? transState.categories : <Category>[];

        return BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, accState) {
            final accounts = accState is AccountsLoaded ? accState.accounts : [];

            return Column(
              children: [
                // Top Search and Filter Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            context.read<TransactionsCubit>().updateSearchQuery(val);
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        isLabelVisible: !filter.isEmpty,
                        child: IconButton.filledTonal(
                          icon: const Icon(Icons.tune),
                          tooltip: 'Filters',
                          onPressed: () => _openFilterSheet(context, filter),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.category_outlined),
                        tooltip: 'Categories',
                        onPressed: () => _openCategoriesPage(context),
                      ),
                    ],
                  ),
                ),

                // Transactions List or Empty State
                Expanded(
                  child: groupedDays.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Transactions Found',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  !filter.isEmpty
                                      ? 'Try adjusting your search query or filters.'
                                      : 'Use the + button to quickly add your expenses and income.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (!filter.isEmpty) ...[
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      context.read<TransactionsCubit>().clearFilter();
                                      setState(() {});
                                    },
                                    child: const Text('Clear Filters'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: groupedDays.length,
                          itemBuilder: (context, dayIndex) {
                            final dayGroup = groupedDays[dayIndex];
                            final isPositive = dayGroup.netTotal.minorUnits > 0;
                            final isNegative = dayGroup.netTotal.minorUnits < 0;
                            final netColor = isPositive
                                ? AppColors.income
                                : (isNegative
                                    ? AppColors.expense
                                    : theme.colorScheme.onSurfaceVariant);
                            final netPrefix = isPositive ? '+' : (isNegative ? '-' : '');

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Section Day Header
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                      Text(
                                        'Net: $netPrefix${dayGroup.netTotal.abs().format()}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: netColor,
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

                                  final Color amountColor;
                                  final String amountText;
                                  if (isTransfer) {
                                    amountColor = AppColors.transfer;
                                    amountText = txn.amount.format();
                                  } else if (isIncome) {
                                    amountColor = AppColors.income;
                                    amountText = '+${txn.amount.format()}';
                                  } else {
                                    amountColor = AppColors.expense;
                                    amountText = '-${txn.amount.format()}';
                                  }

                                  final IconData iconData;
                                  final Color itemColor;
                                  final String titleText;
                                  final String subtitleText;

                                  if (isTransfer) {
                                    iconData = Icons.swap_horiz_outlined;
                                    itemColor = AppColors.transfer;
                                    titleText = 'Transfer';
                                    final noteSuffix = txn.note != null && txn.note!.isNotEmpty ? ' • ${txn.note}' : '';
                                    subtitleText =
                                        '${acc?.name ?? "Account"} → ${dest?.name ?? "Account"}$noteSuffix';
                                  } else {
                                    iconData = cat != null ? _getCategoryIcon(cat.icon) : Icons.category_outlined;
                                    itemColor = cat != null ? Color(cat.color) : theme.colorScheme.primary;
                                    titleText = cat?.name ?? 'Uncategorized';
                                    final noteSuffix = txn.note != null && txn.note!.isNotEmpty ? ' • ${txn.note}' : '';
                                    subtitleText = '${acc?.name ?? "Account"}$noteSuffix';
                                  }

                                  return Column(
                                    children: [
                                      ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                        onTap: () => _openDetailsSheet(context, txn),
                                        leading: CircleAvatar(
                                          backgroundColor: itemColor.withAlpha(35),
                                          child: Icon(iconData, color: itemColor, size: 22),
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
                                        trailing: Text(
                                          amountText,
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: amountColor,
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
