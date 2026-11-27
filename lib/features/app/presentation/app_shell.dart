import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../budgets/presentation/cubit/budgets_cubit.dart';
import '../../budgets/presentation/cubit/budgets_state.dart';
import '../../budgets/presentation/pages/budgets_page.dart';
import '../../budgets/presentation/widgets/set_budget_sheet.dart';
import '../../categories/presentation/cubit/categories_cubit.dart';
import '../../dashboard/presentation/pages/dashboard_page.dart';
import '../../reports/presentation/pages/reports_page.dart';
import '../../savings_goals/presentation/pages/savings_goals_page.dart';
import '../../security/presentation/cubit/security_cubit.dart';
import '../../settings/presentation/cubit/settings_cubit.dart';
import '../../settings/presentation/pages/settings_page.dart';
import '../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../transactions/presentation/pages/transactions_page.dart';
import '../../transactions/presentation/widgets/quick_add_transaction_sheet.dart';
import '../../../core/theme/app_radius.dart';

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

  void _openSetBudgetSheet(BuildContext context) {
    final budgetsState = context.read<BudgetsCubit>().state;
    final year = budgetsState is BudgetsLoaded ? budgetsState.year : DateTime.now().year;
    final month = budgetsState is BudgetsLoaded ? budgetsState.month : DateTime.now().month;
    final existingCategoryIds = budgetsState is BudgetsLoaded
        ? budgetsState.budgets.map((b) => b.category.id).toList()
        : <String>[];

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
          existingBudgetCategoryIds: existingCategoryIds,
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    switch (_currentIndex) {
      case 0: // Dashboard
      case 1: // Transactions
        return FloatingActionButton(
          key: const ValueKey('quick_add_txn_fab'),
          heroTag: 'quick_add_txn_fab',
          tooltip: 'Quick Add Transaction',
          elevation: 4,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          onPressed: () => _openQuickAddSheet(context),
          child: const Icon(Icons.add),
        );
      case 2: // Budgets
        return FloatingActionButton(
          key: const ValueKey('add_budget_fab'),
          heroTag: 'add_budget_fab',
          tooltip: 'Set Category Budget',
          elevation: 4,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          onPressed: () => _openSetBudgetSheet(context),
          child: const Icon(Icons.add),
        );
      case 3: // Savings Goals (handled by SavingsGoalsPage inner FAB)
      case 4: // Reports
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTab = _tabs[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(activeTab.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              final providers = <BlocProvider<dynamic>>[
                BlocProvider<SecurityCubit>.value(value: context.read<SecurityCubit>()),
              ];
              try {
                providers.add(
                  BlocProvider<SettingsCubit>.value(value: context.read<SettingsCubit>()),
                );
              } catch (_) {}

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: providers,
                    child: const SettingsPage(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: activeTab.view,
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorShape: const StadiumBorder(),
          indicatorColor: theme.colorScheme.secondaryContainer.withAlpha(200),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
            );
          }),
        ),
        child: NavigationBar(
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
      ),
    );
  }
}
