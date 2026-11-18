import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/iso_currency.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';

void main() {
  group('Money Value Object', () {
    test('creates Money with minor units and preserves exact integer amount', () {
      const money = Money(1050); // $10.50 in cents
      expect(money.minorUnits, 1050);
      expect(money.currencyCode, 'USD');
      expect(money.isZero, isFalse);
      expect(money.isPositive, isTrue);
      expect(money.isNegative, isFalse);
    });

    test('supports Money.zero constant', () {
      expect(Money.zero.minorUnits, 0);
      expect(Money.zero.currencyCode, 'USD');
      expect(Money.zero.isZero, isTrue);
      expect(Money.zero.isPositive, isFalse);
      expect(Money.zero.isNegative, isFalse);
    });

    test('supports exact addition between two Money instances of same currency', () {
      const a = Money(1050, 'USD');
      const b = Money(525, 'USD');
      final result = a + b;

      expect(result, const Money(1575, 'USD'));
    });

    test('throws CurrencyMismatchFailure when adding differing currencies', () {
      const usd = Money(1050, 'USD');
      const eur = Money(525, 'EUR');

      expect(() => usd + eur, throwsA(isA<CurrencyMismatchFailure>()));
    });

    test('supports exact subtraction between two Money instances of same currency', () {
      const a = Money(1575, 'USD');
      const b = Money(525, 'USD');
      final result = a - b;

      expect(result, const Money(1050, 'USD'));
    });

    test('throws CurrencyMismatchFailure when subtracting differing currencies', () {
      const usd = Money(1575, 'USD');
      const lkr = Money(525, 'LKR');

      expect(() => usd - lkr, throwsA(isA<CurrencyMismatchFailure>()));
    });

    test('supports multiplication by an integer factor preserving currency', () {
      const a = Money(250, 'EUR');
      final result = a * 4;

      expect(result, const Money(1000, 'EUR'));
    });

    test('supports unary negation operator preserving currency', () {
      const a = Money(500, 'GBP');
      expect(-a, const Money(-500, 'GBP'));
    });

    test('supports value equality and comparison operators within same currency', () {
      const a = Money(1000, 'USD');
      const b = Money(1000, 'USD');
      const c = Money(500, 'USD');

      expect(a, equals(b));
      expect(a == b, isTrue);
      expect(a > c, isTrue);
      expect(c < a, isTrue);
      expect(a >= b, isTrue);
      expect(c <= a, isTrue);
    });

    test('comparison throws CurrencyMismatchFailure when comparing differing currencies', () {
      const usd = Money(1000, 'USD');
      const jpy = Money(1000, 'JPY');

      expect(() => usd > jpy, throwsA(isA<CurrencyMismatchFailure>()));
      expect(() => usd < jpy, throwsA(isA<CurrencyMismatchFailure>()));
    });

    test('formats 2-decimal currencies (USD, EUR, LKR) correctly', () {
      const usd = Money(1050, 'USD');
      expect(usd.format(locale: 'en_US'), r'$10.50');

      const negativeUsd = Money(-1050, 'USD');
      expect(negativeUsd.format(locale: 'en_US'), r'-$10.50');

      const lkr = Money(250000, 'LKR');
      expect(lkr.format(locale: 'en_US'), 'Rs2,500.00');
    });

    test('formats 0-decimal currencies (JPY, KRW) without fractional parts', () {
      const jpy = Money(500, 'JPY');
      expect(jpy.format(locale: 'en_US'), '¥500');

      const negativeJpy = Money(-1500, 'JPY');
      expect(negativeJpy.format(locale: 'en_US'), '-¥1,500');
    });

    test('formats 3-decimal currencies (KWD, BHD) with three decimal digits', () {
      const kwd = Money(1500, 'KWD');
      expect(kwd.format(locale: 'en_US'), 'KD1.500');
    });

    test('converts to readable string', () {
      const money = Money(1234, 'EUR');
      expect(money.toString(), 'Money(1234 minor units, EUR)');
    });

    test('boundary handling: supports large minor units without precision loss', () {
      const largeMoney = Money(10000000000, 'USD');
      const oneCent = Money(1, 'USD');
      final sum = largeMoney + oneCent;

      expect(sum.minorUnits, 10000000001);
      expect(sum - oneCent, largeMoney);
    });

    test('boundary handling: handles negative balances correctly', () {
      const debt = Money(-50000, 'USD');
      expect(debt.isNegative, isTrue);
      expect(debt.isPositive, isFalse);
      expect(debt.isZero, isFalse);
      expect(debt < Money.zero, isTrue);
    });

    group('Money.convert', () {
      test('returns identical money when target currency matches source currency', () {
        const money = Money(5000, 'USD');
        final converted = Money.convert(
          from: money,
          toCurrency: 'USD',
          rateScaled: 100000000, // 1.0 * 10^8
        );
        expect(converted, money);
      });

      test('converts USD (2 decimals) to LKR (2 decimals) accurately at rate 300.0', () {
        // 100.00 USD = 10000 minor units. Rate = 300.0 -> 30,000,000,000 scaled
        const usd = Money(10000, 'USD');
        final lkr = Money.convert(
          from: usd,
          toCurrency: 'LKR',
          rateScaled: 30000000000,
        );
        // Expect 30,000.00 LKR = 3,000,000 minor units
        expect(lkr.minorUnits, 3000000);
        expect(lkr.currencyCode, 'LKR');
      });

      test('converts USD (2 decimals) to JPY (0 decimals) accurately at rate 150.0', () {
        // 100.00 USD = 10000 minor units. Rate = 150.0 -> 15,000,000,000 scaled
        const usd = Money(10000, 'USD');
        final jpy = Money.convert(
          from: usd,
          toCurrency: 'JPY',
          rateScaled: 15000000000,
        );
        // Expect 15,000 JPY = 15000 minor units (0 decimals)
        expect(jpy.minorUnits, 15000);
        expect(jpy.currencyCode, 'JPY');
      });

      test('converts JPY (0 decimals) to USD (2 decimals) accurately at rate 0.00666667', () {
        // 15,000 JPY = 15000 minor units. Rate = 0.00666667 -> 666667 scaled
        const jpy = Money(15000, 'JPY');
        final usd = Money.convert(
          from: jpy,
          toCurrency: 'USD',
          rateScaled: 666667,
        );
        // 15000 * 0.00666667 = 100.00 USD = 10000 minor units
        expect(usd.minorUnits, 10000);
        expect(usd.currencyCode, 'USD');
      });

      test('converts USD (2 decimals) to KWD (3 decimals) accurately at rate 0.31', () {
        // 100.00 USD = 10000 minor units. Rate = 0.31 -> 31,000,000 scaled
        const usd = Money(10000, 'USD');
        final kwd = Money.convert(
          from: usd,
          toCurrency: 'KWD',
          rateScaled: 31000000,
        );
        // 100.00 * 0.31 = 31.000 KWD = 31000 minor units (3 decimals)
        expect(kwd.minorUnits, 31000);
        expect(kwd.currencyCode, 'KWD');
      });
    });
  });

  group('IsoCurrency Registry', () {
    test('defines expected decimal fractions and symbols for key currencies', () {
      expect(IsoCurrency.usd.decimalDigits, 2);
      expect(IsoCurrency.usd.scaleFactor, 100);

      expect(IsoCurrency.jpy.decimalDigits, 0);
      expect(IsoCurrency.jpy.scaleFactor, 1);

      expect(IsoCurrency.kwd.decimalDigits, 3);
      expect(IsoCurrency.kwd.scaleFactor, 1000);

      expect(IsoCurrency.lkr.decimalDigits, 2);
      expect(IsoCurrency.lkr.symbol, 'Rs');
    });

    test('fromCode handles case insensitivity and unknown codes gracefully', () {
      expect(IsoCurrency.fromCode('usd'), IsoCurrency.usd);
      expect(IsoCurrency.fromCode('Lkr'), IsoCurrency.lkr);

      final unknown = IsoCurrency.fromCode('XYZ');
      expect(unknown.code, 'XYZ');
      expect(unknown.decimalDigits, 2);
    });
  });
}
