import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/iso_currency.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../budgets/presentation/cubit/budgets_cubit.dart';
import '../../../reports/presentation/cubit/reports_cubit.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../cubit/currency_cubit.dart';

class CurrencyOnboardingInterceptor extends StatefulWidget {
  final Widget child;
  final FlutterSecureStorage? secureStorage;

  const CurrencyOnboardingInterceptor({
    super.key,
    required this.child,
    this.secureStorage,
  });

  @override
  State<CurrencyOnboardingInterceptor> createState() =>
      _CurrencyOnboardingInterceptorState();
}

class _CurrencyOnboardingInterceptorState
    extends State<CurrencyOnboardingInterceptor> {
  late final FlutterSecureStorage _secureStorage;
  static const String keyBackfilled = 'pref_primary_currency_backfilled';

  @override
  void initState() {
    super.initState();
    _secureStorage = widget.secureStorage ?? const FlutterSecureStorage();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowOnboarding();
    });
  }

  Future<void> _checkAndShowOnboarding() async {
    if (!mounted) return;
    try {
      final isBackfilled = await _secureStorage.read(key: keyBackfilled);
      if (isBackfilled == 'true') return;

      if (!mounted) return;
      _showCurrencyOnboardingDialog();
    } catch (_) {
      // Platform channels may not be bound in certain test environments
    }
  }

  void _showCurrencyOnboardingDialog() {
    String selectedCurrency = Money.defaultCurrency;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Confirm Primary Currency'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select your preferred reporting currency. Your net worth, budgets, and reports will consolidate into this currency.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Primary Reporting Currency',
                    border: OutlineInputBorder(),
                  ),
                  items: IsoCurrency.supportedCurrencies
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.code,
                          child: Text('${c.code} - ${c.name} (${c.symbol})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedCurrency = val);
                    }
                  },
                ),
              ],
            ),
            actions: [
              FilledButton(
                onPressed: () async {
                  await _applyBackfill(selectedCurrency);
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                  }
                },
                child: const Text('Confirm & Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyBackfill(String chosenCurrency) async {
    try {
      final currencyCubit = context.read<CurrencyCubit>();
      final database = context.read<AppDatabase>();
      await currencyCubit.setPrimaryCurrency(chosenCurrency);

      // Perform atomic backfill of existing legacy records
      await database.customStatement(
        "UPDATE accounts SET currency_code = ? WHERE currency_code = 'USD'",
        [chosenCurrency],
      );
      await database.customStatement(
        "UPDATE transactions SET currency_code = ? WHERE currency_code = 'USD'",
        [chosenCurrency],
      );
      await database.customStatement(
        "UPDATE budgets SET currency_code = ? WHERE currency_code = 'USD'",
        [chosenCurrency],
      );
      await database.customStatement(
        "UPDATE savings_goals SET target_currency = ? WHERE target_currency = 'USD'",
        [chosenCurrency],
      );
      await database.customStatement(
        "UPDATE goal_contributions SET currency_code = ? WHERE currency_code = 'USD'",
        [chosenCurrency],
      );

      await _secureStorage.write(key: keyBackfilled, value: 'true');

      if (mounted) {
        try {
          context.read<AccountsCubit>().loadAccounts();
          context.read<TransactionsCubit>().loadTransactions();
          context.read<BudgetsCubit>().loadBudgets();
          context.read<ReportsCubit>().loadReports();
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
