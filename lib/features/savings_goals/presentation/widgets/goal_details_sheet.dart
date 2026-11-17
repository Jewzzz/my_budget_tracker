import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/cubit/accounts_state.dart';
import '../../domain/entities/goal_contribution.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/repositories/savings_goal_repository.dart';
import '../cubit/savings_goals_cubit.dart';
import 'create_goal_sheet.dart';

class GoalDetailsSheet extends StatelessWidget {
  final SavingsGoal goal;

  const GoalDetailsSheet({
    super.key,
    required this.goal,
  });

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Savings Goal?'),
        content: Text(
          'Are you sure you want to delete "${goal.name}"? '
          '${goal.savedAmount.isPositive ? "\n\nNote: ${goal.savedAmount.format()} is currently stored in this goal. Consider withdrawing it first." : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<SavingsGoalsCubit>().deleteGoal(goal.id);
              Navigator.pop(context);
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
      builder: (_) => BlocProvider.value(
        value: context.read<SavingsGoalsCubit>(),
        child: CreateGoalSheet(existingGoal: goal),
      ),
    ).then((_) {
      if (context.mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<SavingsGoalRepository>();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  Expanded(
                    child: Text(
                      goal.name,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Target vs Saved Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved: ${goal.savedAmount.format()} / ${goal.targetAmount.format()}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Color(goal.color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openEdit(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final isCompleted = goal.status == SavingsGoalStatus.completed;
                        context.read<SavingsGoalsCubit>().markCompleted(goal.id, !isCompleted);
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        goal.status == SavingsGoalStatus.completed
                            ? Icons.replay
                            : Icons.check_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        goal.status == SavingsGoalStatus.completed
                            ? 'Reactivate'
                            : 'Complete',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    tooltip: 'Delete Goal',
                  ),
                ],
              ),
              const Divider(height: 32),

              // Contribution History Ledger
              Text(
                'Contribution History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<List<GoalContribution>>(
                stream: repo.watchContributions(goal.id),
                builder: (context, snapshot) {
                  final contributions = snapshot.data ?? [];

                  if (contributions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No contributions yet.\nUse Deposit to fund this goal.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  return BlocBuilder<AccountsCubit, AccountsState>(
                    builder: (context, accState) {
                      final accounts = accState is AccountsLoaded ? accState.accounts : [];

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: contributions.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final c = contributions[index];
                          final isDeposit = c.type == GoalContributionType.deposit;
                          final account = accounts.where((a) => a.id == c.accountId).firstOrNull;

                          final color = isDeposit ? AppColors.income : AppColors.expense;
                          final prefix = isDeposit ? '+' : '-';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: color.withAlpha(35),
                              child: Icon(
                                isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
                                color: color,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              isDeposit ? 'Deposit' : 'Withdrawal',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${account?.name ?? "Account"} • ${DateFormat.yMMMd().format(c.date)}'
                              '${c.note != null && c.note!.isNotEmpty ? " • ${c.note}" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            trailing: Text(
                              '$prefix${c.amount.format()}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
