import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            label: 'Total Budgeted',
            amount: totalBudgeted.format(),
            color: theme.colorScheme.onSurface,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.colorScheme.outlineVariant.withAlpha(120),
          ),
          _StatColumn(
            label: 'Total Spent',
            amount: totalSpent.format(),
            color: totalSpent.isPositive ? AppColors.expense : theme.colorScheme.onSurface,
          ),
          Container(
            height: 36,
            width: 1,
            color: theme.colorScheme.outlineVariant.withAlpha(120),
          ),
          _StatColumn(
            label: isNegative ? 'Over Budget' : 'Remaining',
            amount: isNegative ? netRemaining.abs().format() : netRemaining.format(),
            color: remainingColor,
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String amount;
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
        Text(
          amount,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
