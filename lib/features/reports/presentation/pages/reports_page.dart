import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/cash_flow_view.dart';
import '../widgets/category_breakdown_view.dart';
import '../widgets/net_worth_trend_view.dart';
import '../widgets/reports_timeframe_selector.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<ReportsCubit, ReportsState>(
      listener: (context, state) {
        if (state is ReportsLoaded && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ReportsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReportsError) {
          return Center(
            child: AppEmptyState(
              icon: Icons.error_outline,
              title: 'Unable to Load Reports',
              message: state.message,
              actionLabel: 'Retry',
              onAction: () => context.read<ReportsCubit>().loadReports(),
            ),
          );
        }

        if (state is ReportsLoaded) {
          return Scaffold(
            body: Column(
              children: [
                // Timeframe Chips Selector
                ReportsTimeframeSelector(
                  selectedTimeframe: state.timeframe,
                  customRange: state.customRange,
                  onSelected: (timeframe, customRange) {
                    context.read<ReportsCubit>().changeTimeframe(
                          timeframe,
                          customRange: customRange,
                        );
                  },
                ),
                const SizedBox(height: AppSpacing.xs),

                // View Switcher (Segmented Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ReportsView>(
                      style: SegmentedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.smBorder,
                        ),
                        selectedBackgroundColor: theme.colorScheme.primaryContainer,
                        selectedForegroundColor: theme.colorScheme.onPrimaryContainer,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ReportsView.cashFlow,
                          label: Text('Cash Flow'),
                          icon: Icon(Icons.compare_arrows),
                        ),
                        ButtonSegment(
                          value: ReportsView.categoryBreakdown,
                          label: Text('Categories'),
                          icon: Icon(Icons.pie_chart_outline),
                        ),
                        ButtonSegment(
                          value: ReportsView.netWorth,
                          label: Text('Net Worth'),
                          icon: Icon(Icons.show_chart),
                        ),
                      ],
                      selected: {state.selectedView},
                      onSelectionChanged: (newSelection) {
                        context.read<ReportsCubit>().changeView(newSelection.first);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Active View Content
                Expanded(
                  child: switch (state.selectedView) {
                    ReportsView.cashFlow => CashFlowView(report: state.cashFlowReport),
                    ReportsView.categoryBreakdown =>
                      CategoryBreakdownView(report: state.categoryBreakdownReport),
                    ReportsView.netWorth => NetWorthTrendView(report: state.netWorthTrendReport),
                  },
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
