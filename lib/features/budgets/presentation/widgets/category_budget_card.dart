import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/currency/currency_context_extension.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/presentation/components/money_text.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/category_budget_overview.dart';

class CategoryBudgetCard extends StatelessWidget {
  final CategoryBudgetOverview overview;
  final VoidCallback? onTap;

  const CategoryBudgetCard({
    super.key,
    required this.overview,
    this.onTap,
  });

  Color _getProgressColor(double percentage) {
    if (percentage > 1.0) {
      return AppColors.expense;
    } else if (percentage >= 0.8) {
      return AppColors.savings;
    } else {
      return AppColors.income;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = overview.category;
    final catColor = Color(category.color);
    final isOverBudget = overview.isOverBudget;
    final percentage = overview.percentageSpent;
    final progressColor = _getProgressColor(percentage);

    return AppCard(
      borderColor: isOverBudget ? theme.colorScheme.error : null,
      borderWidth: isOverBudget ? 1.5 : null,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top row: Icon, Category Name, Spent of Limit, Over-Budget Badge or Percentage
          Row(
            children: [
              CategoryIconBadge(
                iconName: category.icon,
                color: catColor,
                size: CategoryBadgeSize.medium,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${context.formatMoney(overview.spentAmount)} of ${context.formatMoney(overview.budget.limitAmount)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Over Budget',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: min(1.0, percentage),
              minHeight: 8,
              color: progressColor,
              backgroundColor: progressColor.withAlpha(35),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Bottom status: Remaining or Over by amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isOverBudget)
                MoneyText(
                  amount: overview.spentAmount - overview.budget.limitAmount,
                  prefix: 'Over by ',
                  color: theme.colorScheme.error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                )
              else
                MoneyText(
                  amount: overview.remainingAmount,
                  prefix: 'Remaining: ',
                  color: theme.colorScheme.onSurfaceVariant,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(120),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
