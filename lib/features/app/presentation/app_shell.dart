import 'package:flutter/material.dart';

import '../../dashboard/presentation/pages/dashboard_page.dart';

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
      view: Center(child: Text('Transactions View')),
    ),
    _AppTabItem(
      title: 'Budgets',
      label: 'Budgets',
      icon: Icons.pie_chart_outline,
      selectedIcon: Icons.pie_chart,
      view: Center(child: Text('Budgets View')),
    ),
    _AppTabItem(
      title: 'Savings Goals',
      label: 'Goals',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings,
      view: Center(child: Text('Goals View')),
    ),
    _AppTabItem(
      title: 'Reports',
      label: 'Reports',
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      view: Center(child: Text('Reports View')),
    ),
  ];

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
              // Settings action
            },
          ),
        ],
      ),
      body: activeTab.view,
      floatingActionButton: FloatingActionButton(
        tooltip: 'Quick Add Transaction',
        onPressed: () {
          // Open Quick Add Modal
        },
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
