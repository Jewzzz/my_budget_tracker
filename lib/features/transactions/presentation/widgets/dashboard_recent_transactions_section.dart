import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../domain/entities/transaction.dart';
import '../cubit/transactions_cubit.dart';
import '../cubit/transactions_state.dart';
import 'quick_add_transaction_sheet.dart';

class DashboardRecentTransactionsSection extends StatelessWidget {
  const DashboardRecentTransactionsSection({super.key});

  void _openQuickAddSheet(BuildContext context) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<AccountsCubit>()),
            BlocProvider.value(value: context.read<TransactionsCubit>()),
            BlocProvider.value(value: context.read<CategoriesCubit>()),
          ],
          child: const QuickAddTransactionSheet(),
        ),
      );
    } catch (_) {}
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
                const SizedBox(height: AppSpacing.md),
                if (recent.isEmpty)
                  AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No Transactions Yet',
                    message: 'Tap the + button to log your first transaction.',
                    actionLabel: 'Log Transaction',
                    onAction: () => _openQuickAddSheet(context),
                  )
                else
                  AppCard(
                    padding: EdgeInsets.zero,
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
                        final isExpense = txn.isExpense;

                        final String iconName;
                        final Color itemColor;
                        final String titleText;
                        final String subtitleText;

                        if (isTransfer) {
                          iconName = 'swap_horiz';
                          itemColor = AppColors.transfer;
                          titleText = 'Transfer';
                          subtitleText =
                              '${acc?.name ?? "Account"} → ${dest?.name ?? "Account"} • ${DateFormat.MMMd().format(txn.date)}';
                        } else {
                          iconName = cat?.icon ?? 'category';
                          itemColor = cat != null ? Color(cat.color) : theme.colorScheme.primary;
                          titleText = cat?.name ?? 'Uncategorized';
                          subtitleText =
                              '${acc?.name ?? "Account"} • ${DateFormat.MMMd().format(txn.date)}';
                        }

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
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
