import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/currency/currency.dart';
import 'package:my_budget_tracker/core/currency/currency_formatter.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';

void main() {
  group('SupportedCurrencies', () {
    test('contains all 10 required currencies with USD as default fallback', () {
      expect(SupportedCurrencies.all.length, 10);
      expect(
        SupportedCurrencies.all.map((c) => c.code),
        ['USD', 'LKR', 'GBP', 'EUR', 'INR', 'AUD', 'CAD', 'JPY', 'SGD', 'AED'],
      );
      expect(SupportedCurrencies.fromCode(null), SupportedCurrencies.usd);
      expect(SupportedCurrencies.fromCode(''), SupportedCurrencies.usd);
      expect(SupportedCurrencies.fromCode('UNKNOWN'), SupportedCurrencies.usd);
      expect(SupportedCurrencies.fromCode('lkr'), SupportedCurrencies.lkr);
      expect(SupportedCurrencies.fromCode('AED').symbol, 'د.إ');
    });
  });

  group('CurrencyFormatter', () {
    test('formats all 10 supported currencies without converting minorUnits', () {
      const amount = Money(2500000); // 25,000.00

      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.usd),
        r'$ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.lkr),
        'Rs 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.gbp),
        '£ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.eur),
        '€ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.inr),
        '₹ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.aud),
        r'A$ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.cad),
        r'C$ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.jpy),
        '¥ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.sgd),
        r'S$ 25,000.00',
      );
      expect(
        CurrencyFormatter.formatMoney(amount, currency: SupportedCurrencies.aed),
        '\u2066د.إ\u2069 25,000.00',
      );
      // Verify stored minorUnits are never modified.
      expect(amount.minorUnits, 2500000);
    });

    test('places negative and explicit positive signs before the currency symbol', () {
      const negative = Money(-125050);
      const positive = Money(125050);

      expect(
        CurrencyFormatter.formatMoney(negative, currency: SupportedCurrencies.lkr),
        '-Rs 1,250.50',
      );
      expect(
        CurrencyFormatter.formatMoney(
          positive,
          currency: SupportedCurrencies.gbp,
          showSign: true,
        ),
        '+£ 1,250.50',
      );
      expect(
        CurrencyFormatter.formatMoney(
          negative,
          currency: SupportedCurrencies.aed,
          showSign: true,
        ),
        '-\u2066د.إ\u2069 1,250.50',
      );
    });

    test('formats compact labels and major amounts consistently', () {
      expect(
        CurrencyFormatter.formatCompact(500, currency: SupportedCurrencies.lkr),
        'Rs 500',
      );
      expect(
        CurrencyFormatter.formatCompact(12000, currency: SupportedCurrencies.gbp),
        '£ 12k',
      );
      expect(
        CurrencyFormatter.formatMajor(1450.75, currency: SupportedCurrencies.eur),
        '€ 1,450.75',
      );
    });
  });
}
