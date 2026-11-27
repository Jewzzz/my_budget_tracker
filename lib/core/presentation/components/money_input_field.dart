import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../currency/currency_context_extension.dart';
import '../../theme/app_radius.dart';

class MoneyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? currencySymbol;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const MoneyInputField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.currencySymbol,
    this.autofocus = false,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveSymbol = currencySymbol ?? context.primaryCurrency.symbol;

    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
      ],
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.bold,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '$effectiveSymbol ',
        prefixStyle: theme.textTheme.headlineSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: onChanged,
      validator: validator ??
          (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an amount';
            }
            final sanitized = value.replaceAll(',', '').trim();
            final parts = sanitized.split('.');
            if (parts.length > 2) return 'Invalid amount';
            final dollars = int.tryParse(parts[0]);
            if (dollars == null) return 'Invalid amount';
            int cents = 0;
            if (parts.length == 2) {
              final centsStr = parts[1].padRight(2, '0').substring(0, 2);
              final parsedCents = int.tryParse(centsStr);
              if (parsedCents == null) return 'Invalid amount';
              cents = parsedCents;
            }
            final minorUnits = dollars * 100 + cents;
            if (minorUnits <= 0) {
              return 'Amount must be greater than 0';
            }
            return null;
          },
    );
  }
}
