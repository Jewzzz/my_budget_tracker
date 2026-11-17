import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../cubit/savings_goals_cubit.dart';
import '../cubit/savings_goals_state.dart';
import '../widgets/create_goal_sheet.dart';
import '../widgets/deposit_withdraw_sheet.dart';
import '../widgets/goal_card.dart';
import '../widgets/goal_details_sheet.dart';

class SavingsGoalsPage extends StatelessWidget {
  const SavingsGoalsPage({super.key});

  void _openCreateGoal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: context.read<SavingsGoalsCubit>(),
        child: const CreateGoalSheet(),
      ),
    );
  }

  void _openDepositWithdraw(
    BuildContext context,
    SavingsGoal goal, {
    required bool isDeposit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<SavingsGoalsCubit>()),
          BlocProvider.value(value: context.read<AccountsCubit>()),
        ],
        child: DepositWithdrawSheet(goal: goal, isDeposit: isDeposit),
      ),
    );
  }

  void _openGoalDetails(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<SavingsGoalsCubit>()),
          BlocProvider.value(value: context.read<AccountsCubit>()),
        ],
        child: RepositoryProvider.value(
          value: context.read<SavingsGoalRepository>(),
          child: GoalDetailsSheet(goal: goal),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(BuildContext context, List<SavingsGoal> activeGoals) {
    final theme = Theme.of(context);

    var totalSaved = Money.zero;
    var totalTarget = Money.zero;

    for (final g in activeGoals) {
      totalSaved += g.savedAmount;
      totalTarget += g.targetAmount;
    }

    final remaining = (totalTarget - totalSaved).isNegative
        ? Money.zero
        : totalTarget - totalSaved;
    final progress = totalTarget.isPositive
        ? (totalSaved.minorUnits / totalTarget.minorUnits).clamp(0.0, 1.0)
        : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Saved',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    amount: totalSaved,
                    color: AppColors.income,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Target',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    amount: totalTarget,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Remaining',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  MoneyText(
                    amount: remaining,
                    color: theme.colorScheme.onSurfaceVariant,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: AppColors.income,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}% reached',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.income,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<SavingsGoalsCubit, SavingsGoalsState>(
      listener: (context, state) {
        if (state is SavingsGoalsLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SavingsGoalsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeGoals =
            state is SavingsGoalsLoaded ? state.activeGoals : <SavingsGoal>[];
        final completedGoals =
            state is SavingsGoalsLoaded ? state.completedGoals : <SavingsGoal>[];

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.mdBorder,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(15),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    labelColor: theme.colorScheme.onSurface,
                    unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: [
                      Tab(text: 'Active (${activeGoals.length})'),
                      Tab(text: 'Completed (${completedGoals.length})'),
                    ],
                  ),
                ),
              ),
            ),
            body: TabBarView(
              children: [
                // Active Goals Tab
                activeGoals.isEmpty
                    ? AppEmptyState(
                        icon: Icons.savings_outlined,
                        title: 'No Active Goals',
                        message:
                            'Create your first savings goal and start setting money aside.',
                        actionLabel: 'Create First Goal',
                        onAction: () => _openCreateGoal(context),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        children: [
                          _buildSummaryBanner(context, activeGoals),
                          const SizedBox(height: AppSpacing.md),
                          ...activeGoals.map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: GoalCard(
                                goal: goal,
                                onDeposit: () =>
                                    _openDepositWithdraw(context, goal, isDeposit: true),
                                onWithdraw: () =>
                                    _openDepositWithdraw(context, goal, isDeposit: false),
                                onArchive: () =>
                                    context.read<SavingsGoalsCubit>().markCompleted(goal.id, true),
                                onTap: () => _openGoalDetails(context, goal),
                              ),
                            ),
                          ),
                        ],
                      ),

                // Completed Goals Tab
                completedGoals.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.check_circle_outline,
                        title: 'No Completed Goals',
                        message:
                            'Keep saving! Goals you mark completed will appear here.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: completedGoals.length,
                        itemBuilder: (context, index) {
                          final goal = completedGoals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: GoalCard(
                              goal: goal,
                              onDeposit: () =>
                                  _openDepositWithdraw(context, goal, isDeposit: true),
                              onWithdraw: () =>
                                  _openDepositWithdraw(context, goal, isDeposit: false),
                              onTap: () => _openGoalDetails(context, goal),
                            ),
                          );
                        },
                      ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'add_goal_fab',
              tooltip: 'New Savings Goal',
              onPressed: () => _openCreateGoal(context),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
