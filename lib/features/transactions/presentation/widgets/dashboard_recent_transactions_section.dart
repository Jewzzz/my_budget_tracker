import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';

class DashboardRecentTransactionsSection extends StatelessWidget {
  const DashboardRecentTransactionsSection({super.key});

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
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, transState) {
        if (transState is TransactionsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final recent = transState is TransactionsLoaded
            ? transState.recentTransactions
            : <Transaction>[];
        final categories = transState is TransactionsLoaded
            ? transState.categories
            : <Category>[];

        return BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, accState) {
            final accounts = accState is AccountsLoaded ? accState.accounts : [];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (recent.isEmpty)
                  Card(
                    elevation: 0,
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 40,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No Transactions Yet',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the + button to log your first transaction.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recent.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final txn = recent[index];
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
                          subtitleText =
                              '${acc?.name ?? "Account"} → ${dest?.name ?? "Account"} • ${DateFormat.MMMd().format(txn.date)}';
                        } else {
                          iconData = cat != null ? _getCategoryIcon(cat.icon) : Icons.category_outlined;
                          itemColor = cat != null ? Color(cat.color) : theme.colorScheme.primary;
                          titleText = cat?.name ?? 'Uncategorized';
                          subtitleText =
                              '${acc?.name ?? "Account"} • ${DateFormat.MMMd().format(txn.date)}';
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: itemColor.withAlpha(35),
                            child: Icon(iconData, color: itemColor, size: 20),
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
