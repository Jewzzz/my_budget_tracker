import 'package:flutter/material.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/money.dart';

class BudgetOverviewBanner extends StatelessWidget {
  final Money totalBudgeted;
  final Money totalSpent;
  final Money netRemaining;

  const BudgetOverviewBanner({
    super.key,
    required this.totalBudgeted,
    required this.totalSpent,
    required this.netRemaining,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = netRemaining.isNegative;
    final remainingColor = isNegative
        ? AppColors.expense
        : (netRemaining.isZero ? theme.colorScheme.onSurfaceVariant : AppColors.income);

    final double percentage = totalBudgeted.minorUnits > 0
        ? (totalSpent.minorUnits / totalBudgeted.minorUnits).clamp(0.0, 5.0)
        : 0.0;

    final progressColor = percentage > 1.0
        ? AppColors.expense
        : (percentage >= 0.8 ? AppColors.savings : AppColors.income);

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      color: theme.colorScheme.surfaceContainerHighest.withAlpha(70),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn(
                label: 'Total Budgeted',
                amount: totalBudgeted,
                color: theme.colorScheme.onSurface,
              ),
              Container(
                height: 36,
                width: 1,
                color: theme.colorScheme.outlineVariant.withAlpha(120),
              ),
              _StatColumn(
                label: 'Total Spent',
                amount: totalSpent,
                color: totalSpent.isPositive ? AppColors.expense : theme.colorScheme.onSurface,
              ),
              Container(
                height: 36,
                width: 1,
                color: theme.colorScheme.outlineVariant.withAlpha(120),
              ),
              _StatColumn(
                label: isNegative ? 'Over Budget' : 'Remaining',
                amount: isNegative ? netRemaining.abs() : netRemaining,
                color: remainingColor,
              ),
            ],
          ),
          if (totalBudgeted.isPositive) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      minHeight: 6,
                      color: progressColor,
                      backgroundColor: progressColor.withAlpha(35),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}% used',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final Money amount;
  final Color color;

  const _StatColumn({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        MoneyText(
          amount: amount,
          color: color,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
