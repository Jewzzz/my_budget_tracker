import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../backup/presentation/pages/data_management_page.dart';
import '../../../currency/presentation/pages/currency_settings_page.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../budgets/presentation/cubit/budgets_cubit.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../reports/presentation/cubit/reports_cubit.dart';
import '../../../savings_goals/presentation/cubit/savings_goals_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../cubit/security_cubit.dart';
import '../cubit/security_state.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Set App Lock PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter 4-6 digit PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (val) {
                  if (val == null || !RegExp(r'^\d{4,6}$').hasMatch(val)) {
                    return 'Must be 4 to 6 numeric digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_outlined),
                ),
                validator: (val) {
                  if (val != pinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<SecurityCubit>().enableAppLock(
                      pinController.text.trim(),
                      enableBiometrics: true,
                    );
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('App Lock enabled successfully')),
                );
              }
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
  }

  void _showDisableAppLockDialog(BuildContext context) {
    final pinController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Disable App Lock'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your current PIN to disable App Lock:'),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter PIN';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await context
                    .read<SecurityCubit>()
                    .disableAppLock(pinController.text.trim());
                if (dialogCtx.mounted) {
                  if (success) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('App Lock disabled')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect PIN')),
                    );
                  }
                }
              }
            },
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Change Security PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: oldPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Enter current PIN' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: newPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'New 4-6 digit PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_reset_outlined),
                ),
                validator: (val) {
                  if (val == null || !RegExp(r'^\d{4,6}$').hasMatch(val)) {
                    return 'Must be 4 to 6 numeric digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirm New PIN',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.check_outlined),
                ),
                validator: (val) {
                  if (val != newPinController.text) {
                    return 'PINs do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final success = await context.read<SecurityCubit>().changePin(
                      oldPinController.text.trim(),
                      newPinController.text.trim(),
                    );
                if (dialogCtx.mounted) {
                  if (success) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN updated successfully')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Incorrect current PIN')),
                    );
                  }
                }
              }
            },
            child: const Text('Update PIN'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
      ),
      body: BlocBuilder<SecurityCubit, SecurityState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Text(
                'AUTHENTICATION & LOCK',
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
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                      ),
                      title: const Text(
                        'App Lock',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Require PIN or biometric unlock when opening or resuming app',
                      ),
                      value: state.isAppLockEnabled,
                      onChanged: (enabled) {
                        if (enabled) {
                          _showSetPinDialog(context);
                        } else {
                          _showDisableAppLockDialog(context);
                        }
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withAlpha(80),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.fingerprint, color: theme.colorScheme.primary),
                      ),
                      title: const Text(
                        'Biometric Unlock',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        state.isBiometricsAvailable
                            ? 'Use fingerprint or face recognition'
                            : 'Biometrics not supported on this device',
                      ),
                      value: state.isBiometricsEnabled,
                      onChanged: state.isAppLockEnabled && state.isBiometricsAvailable
                          ? (val) => context.read<SecurityCubit>().toggleBiometrics(val)
                          : null,
                    ),
                    if (state.isAppLockEnabled && state.hasPinSet) ...[
                      const Divider(height: 1),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.pin_outlined),
                        ),
                        title: const Text(
                          'Change PIN',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Update your 4-to-6 digit security PIN'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showChangePinDialog(context),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'CURRENCY & EXCHANGE RATES',
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
                    child: const Icon(Icons.currency_exchange_outlined),
                  ),
                  title: const Text(
                    'Currency & Exchange Rates',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Change primary reporting currency and configure offline rates'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CurrencySettingsPage(),
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
                          onRestoreCompleted: () {
                            try {
                              context.read<AccountsCubit>().loadAccounts();
                              context.read<CategoriesCubit>().loadCategories();
                              context.read<TransactionsCubit>().loadTransactions();
                              context.read<BudgetsCubit>().loadBudgets();
                              context.read<SavingsGoalsCubit>().loadGoals();
                              context.read<ReportsCubit>().loadReports();
                            } catch (_) {
                              // If any cubit is not available in tree
                            }
                          },
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
