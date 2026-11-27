import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/currency/currency_context_extension.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/budgets_cubit.dart';
import '../cubit/budgets_state.dart';

class DashboardBudgetSection extends StatelessWidget {
  const DashboardBudgetSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<BudgetsCubit, BudgetsState>(
      builder: (context, state) {
        if (state is! BudgetsLoaded || state.budgets.isEmpty) {
          return const SizedBox.shrink();
        }

        final totalBudgeted = state.totalBudgeted;
        final totalSpent = state.totalSpent;
        final hasOverBudget = state.hasOverBudget;
        final overBudgetCount = state.overBudgetCount;

        final double percentage = totalBudgeted.minorUnits > 0
            ? totalSpent.minorUnits / totalBudgeted.minorUnits
            : 0.0;

        final progressColor = (hasOverBudget || percentage > 1.0)
            ? AppColors.expense
            : (percentage >= 0.8 ? AppColors.savings : AppColors.income);

        return AppCard(
          borderColor: hasOverBudget ? theme.colorScheme.error : null,
          borderWidth: hasOverBudget ? 1.5 : null,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Monthly Budget',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasOverBudget)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
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
                            'Over-Budget ($overBudgetCount)',
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
                      '${(percentage * 100).toStringAsFixed(0)}% used',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: progressColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.formatMoney(totalSpent)} spent of ${context.formatMoney(totalBudgeted)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    state.netRemaining.isNegative
                        ? 'Over by ${context.formatMoney(state.netRemaining.abs())}'
                        : '${context.formatMoney(state.netRemaining)} left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: state.netRemaining.isNegative
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
