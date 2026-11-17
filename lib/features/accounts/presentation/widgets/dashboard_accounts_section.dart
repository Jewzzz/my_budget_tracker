import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../reports/presentation/pages/reports_page.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_state.dart';
import '../../../transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import '../cubit/accounts_cubit.dart';
import '../cubit/accounts_state.dart';
import 'account_card.dart';
import 'create_account_sheet.dart';

class DashboardAccountsSection extends StatelessWidget {
  const DashboardAccountsSection({super.key});

  void _openCreateAccountSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AccountsCubit>(),
        child: const CreateAccountSheet(),
      ),
    );
  }

  void _openQuickAddSheet(
    BuildContext context, {
    TransactionType initialType = TransactionType.expense,
  }) {
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
          child: QuickAddTransactionSheet(initialType: initialType),
        ),
      );
    } catch (_) {}
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Reports')),
          body: const ReportsPage(),
        ),
      ),
    );
  }

  Widget _buildCashFlowPills(BuildContext context, ThemeData theme) {
    TransactionsState? transState;
    try {
      transState = context.watch<TransactionsCubit>().state;
    } catch (_) {
      return const SizedBox.shrink();
    }

    if (transState is! TransactionsLoaded) return const SizedBox.shrink();

    final now = DateTime.now();
    final monthTxns = transState.allTransactions.where(
      (t) => t.date.year == now.year && t.date.month == now.month,
    );

    var incomeTotal = Money.zero;
    var expenseTotal = Money.zero;
    for (final t in monthTxns) {
      if (t.isIncome) incomeTotal += t.amount;
      if (t.isExpense) expenseTotal += t.amount;
    }

    if (incomeTotal.isZero && expenseTotal.isZero) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          // Income pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.income.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.income.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward, size: 13, color: AppColors.income),
                const SizedBox(width: 4),
                MoneyText(
                  amount: incomeTotal,
                  showSign: true,
                  color: AppColors.income,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Expense pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.expense.withAlpha(25),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.expense.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_downward, size: 13, color: AppColors.expense),
                const SizedBox(width: 4),
                MoneyText(
                  amount: -expenseTotal,
                  color: AppColors.expense,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AccountsCubit, AccountsState>(
      listener: (context, state) {
        if (state is AccountsLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AccountsLoading || state is AccountsInitial) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is AccountsError) {
          return Center(child: Text('Error: ${state.message}'));
        }

        final loaded = state as AccountsLoaded;
        final accounts = loaded.accounts;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Executive Net Worth Hero Card
            AppCard(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xl,
              ),
              color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
              borderRadius: AppRadius.cardBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Balance',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Net Worth',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MoneyText(
                    amount: loaded.totalBalance,
                    autoColor: loaded.totalBalance.isNegative,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Real-time Monthly Cash Flow Indicator Pills
                  _buildCashFlowPills(context, theme),

                  const SizedBox(height: AppSpacing.lg),

                  // Quick Action Shortcuts Row
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openQuickAddSheet(context),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Quick Add'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smBorder,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _openQuickAddSheet(
                          context,
                          initialType: TransactionType.transfer,
                        ),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('Transfer'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smBorder,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _openReports(context),
                        icon: const Icon(Icons.bar_chart_outlined, size: 18),
                        label: const Text('View Reports'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.smBorder,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Accounts Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Accounts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Account'),
                  onPressed: () => _openCreateAccountSheet(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Accounts List or Empty State
            if (accounts.isEmpty)
              AppEmptyState(
                icon: Icons.account_balance_outlined,
                title: 'No Accounts Yet',
                message: 'Add your checking, savings, or cash accounts to track balances.',
                actionLabel: 'Add Account',
                onAction: () => _openCreateAccountSheet(context),
              )
            else
              SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    return AccountCard(account: accounts[index]);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
