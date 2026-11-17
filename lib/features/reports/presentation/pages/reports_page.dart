import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.read<ReportsCubit>().loadReports(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
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
                const SizedBox(height: 8),

                // View Switcher (Segmented Button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SegmentedButton<ReportsView>(
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
                const SizedBox(height: 12),

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
