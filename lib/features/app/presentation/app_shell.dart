import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../budgets/presentation/pages/budgets_page.dart';
import '../../categories/presentation/cubit/categories_cubit.dart';
import '../../dashboard/presentation/pages/dashboard_page.dart';
import '../../reports/presentation/pages/reports_page.dart';
import '../../savings_goals/presentation/pages/savings_goals_page.dart';
import '../../security/presentation/cubit/security_cubit.dart';
import '../../security/presentation/pages/security_settings_page.dart';
import '../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../transactions/presentation/pages/transactions_page.dart';
import '../../transactions/presentation/widgets/quick_add_transaction_sheet.dart';

class _AppTabItem {
  final String title;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget view;

  const _AppTabItem({
    required this.title,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.view,
  });
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  static const List<_AppTabItem> _tabs = [
    _AppTabItem(
      title: 'Dashboard',
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      view: DashboardPage(),
    ),
    _AppTabItem(
      title: 'Transactions',
      label: 'Transactions',
      icon: Icons.receipt_long_outlined,
      selectedIcon: Icons.receipt_long,
      view: TransactionsPage(),
    ),
    _AppTabItem(
      title: 'Budgets',
      label: 'Budgets',
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
      view: BudgetsPage(),
    ),
    _AppTabItem(
      title: 'Savings Goals',
      label: 'Goals',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
      view: SavingsGoalsPage(),
    ),
    _AppTabItem(
      title: 'Reports',
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      view: ReportsPage(),
    ),
  ];

  void _openQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<AccountsCubit>()),
          BlocProvider.value(value: context.read<TransactionsCubit>()),
          BlocProvider.value(value: context.read<CategoriesCubit>()),
        ],
        child: const QuickAddTransactionSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(activeTab.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<SecurityCubit>(),
                    child: const SecuritySettingsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: activeTab.view,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Quick Add Transaction',
        onPressed: () => _openQuickAddSheet(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
