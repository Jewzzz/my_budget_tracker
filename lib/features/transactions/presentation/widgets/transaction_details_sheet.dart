import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/components/app_bottom_sheet.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';
import 'edit_transaction_sheet.dart';

class TransactionDetailsSheet extends StatelessWidget {
  final Transaction transaction;

  const TransactionDetailsSheet({
    super.key,
    required this.transaction,
  });

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
      default:
        return Icons.category_outlined;
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: const Text(
          'Are you sure you want to delete this transaction? The associated account balance will be reverted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              context.read<TransactionsCubit>().deleteTransaction(transaction.id);
              Navigator.pop(context); // Close details sheet
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Transaction deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openEdit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountsCubit>()),
          BlocProvider.value(value: context.read<TransactionsCubit>()),
        ],
        child: EditTransactionSheet(transaction: transaction),
      ),
    ).then((updated) {
      if (updated == true && context.mounted) {
        Navigator.pop(context); // Close details sheet on successful update
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, transState) {
        final categories = transState is TransactionsLoaded ? transState.categories : <Category>[];
        final cat = categories.where((c) => c.id == transaction.categoryId).firstOrNull;

        return BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, accState) {
            final accounts = accState is AccountsLoaded ? accState.accounts : [];
            final acc = accounts.where((a) => a.id == transaction.accountId).firstOrNull;
            final dest = accounts.where((a) => a.id == transaction.destinationAccountId).firstOrNull;

            final Color amountColor;
            final String amountText;
            if (transaction.isTransfer) {
              amountColor = AppColors.transfer;
              amountText = transaction.amount.format();
            } else if (transaction.isIncome) {
              amountColor = AppColors.income;
              amountText = '+${transaction.amount.format()}';
            } else {
              amountColor = AppColors.expense;
              amountText = '-${transaction.amount.format()}';
            }

            final IconData iconData;
            final Color itemColor;
            final String titleText;
            if (transaction.isTransfer) {
              iconData = Icons.swap_horiz_outlined;
              itemColor = AppColors.transfer;
              titleText = 'Transfer';
            } else {
              iconData = cat != null ? _getCategoryIcon(cat.icon) : Icons.category_outlined;
              itemColor = cat != null ? Color(cat.color) : theme.colorScheme.primary;
              titleText = cat?.name ?? 'Uncategorized';
            }

            return AppBottomSheet(
              title: 'Transaction Details',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header icon, title, and amount
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: itemColor.withAlpha(35),
                          child: Icon(iconData, color: itemColor, size: 28),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                titleText,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                transaction.type.name[0].toUpperCase() + transaction.type.name.substring(1),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          amountText,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Details list
                  if (transaction.isTransfer) ...[
                    _DetailRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Source Account',
                      value: acc?.name ?? 'Unknown',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.savings_outlined,
                      label: 'Destination Account',
                      value: dest?.name ?? 'Unknown',
                    ),
                  ] else ...[
                    _DetailRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Account',
                      value: acc?.name ?? 'Unknown',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.category_outlined,
                      label: 'Category',
                      value: cat?.name ?? 'Uncategorized',
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat.yMMMd().format(transaction.date),
                  ),
                  if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    _DetailRow(
                      icon: Icons.notes_outlined,
                      label: 'Note',
                      value: transaction.note!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context),
                          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                          label: Text(
                            'Delete',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: theme.colorScheme.error),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _openEdit(context),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
