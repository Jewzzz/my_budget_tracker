import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
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

    int totalSavedMinor = 0;
    int totalTargetMinor = 0;

    for (final g in activeGoals) {
      totalSavedMinor += g.savedAmount.minorUnits;
      totalTargetMinor += g.targetAmount.minorUnits;
    }

    final totalSaved = Money(totalSavedMinor);
    final totalTarget = Money(totalTargetMinor);
    final remainingMinor = (totalTargetMinor - totalSavedMinor).clamp(0, totalTargetMinor);
    final remaining = Money(remainingMinor);
    final progress = totalTargetMinor > 0 ? (totalSavedMinor / totalTargetMinor).clamp(0.0, 1.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                    Text(
                      totalSaved.format(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.income,
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
                    Text(
                      totalTarget.format(),
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
                    Text(
                      remaining.format(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
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

        final activeGoals = state is SavingsGoalsLoaded ? state.activeGoals : <SavingsGoal>[];
        final completedGoals = state is SavingsGoalsLoaded ? state.completedGoals : <SavingsGoal>[];

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: Container(
                color: theme.scaffoldBackgroundColor,
                child: TabBar(
                  tabs: [
                    Tab(text: 'Active (${activeGoals.length})'),
                    Tab(text: 'Completed (${completedGoals.length})'),
                  ],
                ),
              ),
            ),
            body: TabBarView(
              children: [
                // Active Goals Tab
                activeGoals.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Active Goals',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create your first savings goal and start setting money aside.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () => _openCreateGoal(context),
                                icon: const Icon(Icons.add),
                                label: const Text('Create First Goal'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        children: [
                          _buildSummaryBanner(context, activeGoals),
                          const SizedBox(height: 16),
                          ...activeGoals.map(
                            (goal) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GoalCard(
                                goal: goal,
                                onDeposit: () => _openDepositWithdraw(context, goal, isDeposit: true),
                                onWithdraw: () => _openDepositWithdraw(context, goal, isDeposit: false),
                                onTap: () => _openGoalDetails(context, goal),
                              ),
                            ),
                          ),
                        ],
                      ),

                // Completed Goals Tab
                completedGoals.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No Completed Goals',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Keep saving! Goals you mark completed will appear here.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: completedGoals.length,
                        itemBuilder: (context, index) {
                          final goal = completedGoals[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GoalCard(
                              goal: goal,
                              onDeposit: () => _openDepositWithdraw(context, goal, isDeposit: true),
                              onWithdraw: () => _openDepositWithdraw(context, goal, isDeposit: false),
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
