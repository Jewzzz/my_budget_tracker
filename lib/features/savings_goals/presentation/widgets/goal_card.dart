import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/savings_goals_cubit.dart';

class GoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final VoidCallback? onDeposit;
  final VoidCallback? onWithdraw;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.onDeposit,
    this.onWithdraw,
    this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'savings':
        return Icons.savings_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'computer':
        return Icons.computer_outlined;
      case 'favorite':
        return Icons.favorite_border;
      case 'beach_access':
        return Icons.beach_access_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'diamond':
        return Icons.diamond_outlined;
      default:
        return Icons.savings_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(goal.color);
    final is100Percent = goal.progressPercentage >= 1.0;
    final isCompleted = goal.status == SavingsGoalStatus.completed;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: (is100Percent || isCompleted)
              ? AppColors.income
              : theme.colorScheme.outlineVariant.withAlpha(120),
          width: (is100Percent || isCompleted) ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Celebratory completion banner if 100% or completed
              if (is100Percent || isCompleted) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.income.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.income.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isCompleted ? 'Goal Completed!' : 'Goal Target Reached!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                      if (!isCompleted)
                        TextButton(
                          onPressed: () {
                            context.read<SavingsGoalsCubit>().markCompleted(goal.id, true);
                          },
                          child: const Text('Archive'),
                        ),
                    ],
                  ),
                ),
              ],

              // Header: Icon, Name, Target Date, Percentage
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: color.withAlpha(35),
                    child: Icon(_getIconData(goal.icon), color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
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
              const SizedBox(height: 14),

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
              const SizedBox(height: 8),

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
              const SizedBox(height: 14),

              // Action Buttons: Deposit & Withdraw
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: onDeposit,
                      icon: const Icon(Icons.arrow_downward, size: 16),
                      label: const Text('Deposit'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: goal.savedAmount.isPositive ? onWithdraw : null,
                      icon: const Icon(Icons.arrow_upward, size: 16),
                      label: const Text('Withdraw'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
