import 'package:flutter/material.dart';
import 'package:my_budget_tracker/features/accounts/presentation/widgets/dashboard_accounts_section.dart';
import 'package:my_budget_tracker/features/budgets/presentation/widgets/dashboard_budget_section.dart';
import 'package:my_budget_tracker/features/transactions/presentation/widgets/dashboard_recent_transactions_section.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardAccountsSection(),
          SizedBox(height: 16),
          DashboardBudgetSection(),
          SizedBox(height: 16),
          DashboardRecentTransactionsSection(),
        ],
      ),
    );
  }
}
