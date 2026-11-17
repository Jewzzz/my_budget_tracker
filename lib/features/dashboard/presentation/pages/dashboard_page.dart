import 'package:flutter/material.dart';
import 'package:my_budget_tracker/features/accounts/presentation/widgets/dashboard_accounts_section.dart';

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
        ],
      ),
    );
  }
}
