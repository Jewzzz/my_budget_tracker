import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../backup/presentation/pages/data_management_page.dart';
import '../../../budgets/presentation/cubit/budgets_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../reports/presentation/cubit/reports_cubit.dart';
import '../../../savings_goals/presentation/cubit/savings_goals_cubit.dart';
import '../../../security/presentation/cubit/security_cubit.dart';
import '../../../security/presentation/pages/security_settings_page.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/currency_picker_sheet.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _openCurrencyPicker(BuildContext context) {
    final settingsCubit = context.read<SettingsCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider.value(
        value: settingsCubit,
        child: const CurrencyPickerSheet(),
      ),
    );
  }

  void _reloadAllCubits(BuildContext context) {
    try {
      context.read<AccountsCubit>().loadAccounts();
    } catch (_) {}
    try {
      context.read<CategoriesCubit>().loadCategories();
    } catch (_) {}
    try {
      context.read<TransactionsCubit>().loadTransactions();
    } catch (_) {}
    try {
      context.read<BudgetsCubit>().loadBudgets();
    } catch (_) {}
    try {
      context.read<SavingsGoalsCubit>().loadGoals();
    } catch (_) {}
    try {
      context.read<ReportsCubit>().loadReports();
    } catch (_) {}
    try {
      context.read<SettingsCubit>().loadSettings();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final currency = settingsState.primaryCurrency;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Text(
                'PREFERENCES',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                ),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      currency.symbol,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  title: const Text(
                    'Primary Currency',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${currency.name} (${currency.code})'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openCurrencyPicker(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'SECURITY',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(80),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.security_outlined, color: theme.colorScheme.primary),
                  ),
                  title: const Text(
                    'Security Settings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('App Lock, Biometric Unlock, and Security PIN'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final securityCubit = context.read<SecurityCubit>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: securityCubit,
                          child: const SecuritySettingsPage(),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'DATA & STORAGE',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant.withAlpha(120)),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.backup_outlined),
                  ),
                  title: const Text(
                    'Data Backup & Export',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Export snapshots, restore from backup, or export CSV'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DataManagementPage(
                          onRestoreCompleted: () => _reloadAllCubits(context),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
