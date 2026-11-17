import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/savings_goals_cubit.dart';

class GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;

  const GoalCard({
    super.key,
    required this.goal,
    this.onDeposit,
    this.onWithdraw,
    this.onTap,
    this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(goal.color);
    final is100Percent = goal.progressPercentage >= 1.0;
    final isCompleted = goal.status == SavingsGoalStatus.completed;

    return AppCard(
      borderColor: (is100Percent || isCompleted) ? AppColors.income : null,
      borderWidth: (is100Percent || isCompleted) ? 1.5 : null,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Celebratory completion banner if 100% or completed
          if (is100Percent || isCompleted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.income.withAlpha(25),
                borderRadius: AppRadius.smBorder,
                border: Border.all(color: AppColors.income.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      isCompleted ? 'Goal Completed!' : 'Goal Target Reached!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.income,
                      ),
                    ),
                  ),
                  if (!isCompleted)
                    TextButton(
                      onPressed: onArchive ??
                          () => context.read<SavingsGoalsCubit>().markCompleted(goal.id, true),
                      child: const Text('Archive'),
                    ),
                ],
              ),
            ),
          ],

          // Header: Icon, Name, Target Date, Percentage
          Row(
            children: [
              CategoryIconBadge(
                iconName: goal.icon,
                color: color,
                size: CategoryBadgeSize.medium,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (goal.targetDate != null)
                      Text(
                        'Target: ${DateFormat.yMMMd().format(goal.targetDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                '${(goal.progressPercentage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: is100Percent ? AppColors.income : color,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: goal.progressPercentage,
              minHeight: 8,
              color: is100Percent ? AppColors.income : color,
              backgroundColor: color.withAlpha(35),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Amounts: Saved vs Target & Remaining
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.savedAmount.format()} of ${goal.targetAmount.format()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                goal.isCompleted
                    ? 'Completed'
                    : 'Remaining: ${goal.remainingAmount.format()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Action Buttons: Deposit & Withdraw
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onDeposit,
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  label: const Text('Deposit'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: goal.savedAmount.isPositive ? onWithdraw : null,
                  icon: const Icon(Icons.arrow_upward, size: 16),
                  label: const Text('Withdraw'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.smBorder),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
