import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/app/presentation/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BudgetTrackerApp());
}

class BudgetTrackerApp extends StatelessWidget {
  const BudgetTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Budget Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AppShell(),
    );
  }
}
