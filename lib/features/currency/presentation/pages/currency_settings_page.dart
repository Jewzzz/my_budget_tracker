import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/value_objects/iso_currency.dart';
import '../cubit/currency_cubit.dart';
import '../cubit/currency_state.dart';

class CurrencySettingsPage extends StatelessWidget {
  const CurrencySettingsPage({super.key});

  void _showChangePrimaryCurrencyDialog(BuildContext context, String currentCurrency) {
    String selected = currentCurrency;
    final cubit = context.read<CurrencyCubit>();
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Primary Reporting Currency'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'High-level dashboards, monthly budgets, and reports will consolidate into this currency.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                value: selected,
                decoration: const InputDecoration(
                  labelText: 'Reporting Currency',
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
                    setState(() => selected = val);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                cubit.setPrimaryCurrency(selected);
                Navigator.pop(dialogCtx);
                messenger.showSnackBar(
                  SnackBar(content: Text('Primary currency updated to $selected')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRateDialog(
    BuildContext context, {
    required String baseCurrency,
    required String targetCurrency,
    required int currentRateScaled,
  }) {
    final cubit = context.read<CurrencyCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final rateController = TextEditingController(
      text: (currentRateScaled / 100000000.0).toStringAsFixed(4),
    );
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Edit Rate: $baseCurrency / $targetCurrency'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: rateController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '1 $baseCurrency = X $targetCurrency',
              border: const OutlineInputBorder(),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter a rate';
              final parsed = double.tryParse(val.trim());
              if (parsed == null || parsed <= 0) return 'Invalid rate';
              return null;
            },
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
                final rate = double.parse(rateController.text.trim());
                final scaled = (rate * 100000000).round();
                cubit.setExchangeRate(
                  baseCurrency: baseCurrency,
                  targetCurrency: targetCurrency,
                  rateScaled: scaled,
                );
                Navigator.pop(dialogCtx);
                messenger.showSnackBar(
                  SnackBar(content: Text('Rate updated for $baseCurrency/$targetCurrency')),
                );
              }
            },
            child: const Text('Save Rate'),
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
        title: const Text('Currency & Exchange Rates'),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        builder: (context, state) {
          final iso = IsoCurrency.fromCode(state.primaryCurrency);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              Text(
                'REPORTING PREFERENCE',
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
                      color: AppColors.income.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      iso.symbol,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.income,
                      ),
                    ),
                  ),
                  title: const Text(
                    'Primary Reporting Currency',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${iso.code} - ${iso.name}'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => _showChangePrimaryCurrencyDialog(context, state.primaryCurrency),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              Text(
                'OFFLINE EXCHANGE RATES',
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
                child: state.rates.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No exchange rates stored')),
                      )
                    : Column(
                        children: [
                          for (int i = 0; i < state.rates.length; i++) ...[
                            if (i > 0) const Divider(height: 1),
                            ListTile(
                              title: Text(
                                '${state.rates[i].baseCurrency} → ${state.rates[i].targetCurrency}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '1 ${state.rates[i].baseCurrency} = ${state.rates[i].rateAsDouble.toStringAsFixed(4)} ${state.rates[i].targetCurrency}',
                              ),
                              trailing: const Icon(Icons.edit_outlined, size: 20),
                              onTap: () => _showEditRateDialog(
                                context,
                                baseCurrency: state.rates[i].baseCurrency,
                                targetCurrency: state.rates[i].targetCurrency,
                                currentRateScaled: state.rates[i].rateScaled,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
