import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../domain/entities/category_budget_overview.dart';
import '../cubit/budgets_cubit.dart';
import '../cubit/budgets_state.dart';
import '../widgets/budget_overview_banner.dart';
import '../widgets/category_budget_card.dart';
import '../widgets/set_budget_sheet.dart';

class BudgetsPage extends StatelessWidget {
  const BudgetsPage({super.key});

  void _openSetBudgetSheet(
    BuildContext context, {
    required int year,
    required int month,
    CategoryBudgetOverview? existingOverview,
    List<String> existingCategoryIds = const [],
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<BudgetsCubit>()),
          BlocProvider.value(value: context.read<CategoriesCubit>()),
        ],
        child: SetBudgetSheet(
          year: year,
          month: month,
          existingOverview: existingOverview,
          existingBudgetCategoryIds: existingCategoryIds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<BudgetsCubit, BudgetsState>(
      listener: (context, state) {
        if (state is BudgetsLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BudgetsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final year = state is BudgetsLoaded ? state.year : DateTime.now().year;
        final month = state is BudgetsLoaded ? state.month : DateTime.now().month;
        final budgets = state is BudgetsLoaded ? state.budgets : <CategoryBudgetOverview>[];

        final monthDate = DateTime(year, month);
        final formattedMonth = DateFormat.yMMMM().format(monthDate);
        final existingCategoryIds = budgets.map((b) => b.category.id).toList();

        return Scaffold(
          body: Column(
            children: [
              // Calendar Month Switcher Header (< May 2026 >)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chevron_left),
                      tooltip: 'Previous Month',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                      ),
                      onPressed: () => context.read<BudgetsCubit>().previousMonth(),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          formattedMonth,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.chevron_right),
                      tooltip: 'Next Month',
                      style: IconButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                      ),
                      onPressed: () => context.read<BudgetsCubit>().nextMonth(),
                    ),
                  ],
                ),
              ),

              // Overview Banner
              if (state is BudgetsLoaded)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: BudgetOverviewBanner(
                    totalBudgeted: state.totalBudgeted,
                    totalSpent: state.totalSpent,
                    netRemaining: state.netRemaining,
                  ),
                ),
              const SizedBox(height: AppSpacing.md),

              // Category Budgets List or Empty State
              Expanded(
                child: budgets.isEmpty
                    ? AppEmptyState(
                        icon: Icons.pie_chart_outline,
                        title: 'No Budgets for $formattedMonth',
                        message:
                            'Set spending limits for your expense categories to keep spending on track.',
                        actionLabel: 'Set First Budget',
                        onAction: () => _openSetBudgetSheet(
                          context,
                          year: year,
                          month: month,
                          existingCategoryIds: existingCategoryIds,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        itemCount: budgets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          final overview = budgets[index];
                          return CategoryBudgetCard(
                            overview: overview,
                            onTap: () => _openSetBudgetSheet(
                              context,
                              year: year,
                              month: month,
                              existingOverview: overview,
                              existingCategoryIds: existingCategoryIds,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            heroTag: 'add_budget_fab',
            tooltip: 'Set Category Budget',
            onPressed: () => _openSetBudgetSheet(
              context,
              year: year,
              month: month,
              existingCategoryIds: existingCategoryIds,
            ),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
