import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../value_objects/money.dart';
import 'currency.dart';
import 'currency_formatter.dart';

extension CurrencyContextExtension on BuildContext {
  /// Watches the active Primary Currency from [SettingsCubit], safely falling
  /// back to [SupportedCurrencies.usd] in isolated tests without a provider.
  Currency get primaryCurrency {
    try {
      return watch<SettingsCubit>().state.primaryCurrency;
    } catch (_) {
      return SupportedCurrencies.usd;
    }
  }

  /// Formats [amount] using the watched Primary Currency without converting minor units.
  String formatMoney(Money amount, {bool showSign = false}) {
    return CurrencyFormatter.formatMoney(
      amount,
      currency: primaryCurrency,
      showSign: showSign,
    );
  }

  /// Formats a major-unit double [amount] using the watched Primary Currency.
  String formatMajorCurrency(double amount, {bool showSign = false}) {
    return CurrencyFormatter.formatMajor(
      amount,
      currency: primaryCurrency,
      showSign: showSign,
    );
  }

  /// Formats a compact major-unit label (e.g. chart axes) using the watched Primary Currency.
  String formatCompactCurrency(double majorValue) {
    return CurrencyFormatter.formatCompact(
      majorValue,
      currency: primaryCurrency,
    );
  }
}
