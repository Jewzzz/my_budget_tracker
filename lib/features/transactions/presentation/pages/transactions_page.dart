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

class TransactionsPage extends StatelessWidget {
  const TransactionsPage({super.key});

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

        final transactions = transState is TransactionsLoaded
            ? transState.allTransactions
            : <Transaction>[];
        final categories = transState is TransactionsLoaded
            ? transState.categories
            : <Category>[];

        return BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, accState) {
            final accounts = accState is AccountsLoaded ? accState.accounts : [];

            if (transactions.isEmpty) {
              return Center(
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
                        'Use the + button to quickly add your expenses and income.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: transactions.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final txn = transactions[index];
                final cat = categories.where((c) => c.id == txn.categoryId).firstOrNull;
                final acc = accounts.where((a) => a.id == txn.accountId).firstOrNull;

                final isIncome = txn.isIncome;
                final amountColor = isIncome ? AppColors.income : AppColors.expense;
                final amountPrefix = isIncome ? '+' : '-';

                final iconData = cat != null ? _getCategoryIcon(cat.icon) : Icons.category_outlined;
                final catColor = cat != null ? Color(cat.color) : theme.colorScheme.primary;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: catColor.withAlpha(35),
                    child: Icon(iconData, color: catColor, size: 22),
                  ),
                  title: Text(
                    cat?.name ?? (txn.isTransfer ? 'Transfer' : 'Uncategorized'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${acc?.name ?? "Account"} • ${DateFormat.yMMMd().format(txn.date)}${txn.note != null && txn.note!.isNotEmpty ? " • ${txn.note}" : ""}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: Text(
                    '$amountPrefix${txn.amount.format()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
