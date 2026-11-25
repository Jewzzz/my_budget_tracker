import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_radius.dart';
import '../../value_objects/iso_currency.dart';
import '../../value_objects/money.dart';

class MoneyInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? currencySymbol;
  final String currencyCode;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const MoneyInputField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.currencySymbol,
    this.currencyCode = Money.defaultCurrency,
    this.autofocus = false,
    this.onChanged,
    this.validator,
  });

  static int? parseMinorUnits(String value, [String currencyCode = Money.defaultCurrency]) {
    if (value.trim().isEmpty) return null;
    final sanitized = value.replaceAll(',', '').trim();
    final parts = sanitized.split('.');
    if (parts.length > 2) return null;

    final majors = int.tryParse(parts[0]);
    if (majors == null) return null;

    final iso = IsoCurrency.fromCode(currencyCode);
    final decimals = iso.decimalDigits;
    int minorUnits = majors * iso.scaleFactor;

    if (parts.length == 2 && decimals > 0) {
      final fracStr = parts[1].padRight(decimals, '0').substring(0, decimals);
      final frac = int.tryParse(fracStr);
      if (frac == null) return null;
      minorUnits += frac;
    }
    return minorUnits;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iso = IsoCurrency.fromCode(currencyCode);
    final effectiveSymbol = currencySymbol ?? iso.symbol;
    final decimals = iso.decimalDigits;

    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.numberWithOptions(decimal: decimals > 0),
      inputFormatters: [
        if (decimals == 0)
          FilteringTextInputFormatter.digitsOnly
        else
          FilteringTextInputFormatter.allow(RegExp('^\\d*\\.?\\d{0,$decimals}')),
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
            final minorUnits = parseMinorUnits(value, currencyCode);
            if (minorUnits == null) return 'Invalid amount';
            if (minorUnits <= 0) {
              return 'Amount must be greater than 0';
            }
            return null;
          },
    );
  }
}
