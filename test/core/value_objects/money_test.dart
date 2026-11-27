import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/currency/currency.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';

void main() {
  group('Money Value Object', () {
    test('creates Money with minor units and preserves exact integer amount', () {
      const money = Money(1050); // $10.50 in cents
      expect(money.minorUnits, 1050);
      expect(money.isZero, isFalse);
      expect(money.isPositive, isTrue);
      expect(money.isNegative, isFalse);
    });

    test('supports Money.zero constant', () {
      expect(Money.zero.minorUnits, 0);
      expect(Money.zero.isZero, isTrue);
      expect(Money.zero.isPositive, isFalse);
      expect(Money.zero.isNegative, isFalse);
    });

    test('supports exact addition between two Money instances', () {
      const a = Money(1050);
      const b = Money(525);
      final result = a + b;

      expect(result, const Money(1575));
    });

    test('supports exact subtraction between two Money instances', () {
      const a = Money(1575);
      const b = Money(525);
      final result = a - b;

      expect(result, const Money(1050));
    });

    test('supports multiplication by an integer factor', () {
      const a = Money(250);
      final result = a * 4;

      expect(result, const Money(1000));
    });

    test('supports unary negation operator', () {
      const a = Money(500);
      expect(-a, const Money(-500));
    });

    test('supports value equality and comparison operators', () {
      const a = Money(1000);
      const b = Money(1000);
      const c = Money(500);

      expect(a, equals(b));
      expect(a == b, isTrue);
      expect(a > c, isTrue);
      expect(c < a, isTrue);
      expect(a >= b, isTrue);
      expect(c <= a, isTrue);
    });

    test('formats currency with locale and symbol correctly', () {
      const money = Money(1050);
      expect(money.format(currencyCode: 'USD', locale: 'en_US'), r'$ 10.50');
      expect(money.format(currency: SupportedCurrencies.lkr), 'Rs 10.50');

      const negativeMoney = Money(-1050);
      expect(negativeMoney.format(currencyCode: 'USD', locale: 'en_US'), r'-$ 10.50');
    });

    test('converts to readable string', () {
      const money = Money(1234);
      expect(money.toString(), 'Money(1234 minor units)');
    });

    test('boundary handling: supports large minor units without precision loss', () {
      // 100 million dollars in cents = 10,000,000,000 cents
      const largeMoney = Money(10000000000);
      const oneCent = Money(1);
      final sum = largeMoney + oneCent;

      expect(sum.minorUnits, 10000000001);
      expect(sum - oneCent, largeMoney);
    });

    test('boundary handling: handles negative balances correctly', () {
      const debt = Money(-50000); // -$500.00
      expect(debt.isNegative, isTrue);
      expect(debt.isPositive, isFalse);
      expect(debt.isZero, isFalse);
      expect(debt < Money.zero, isTrue);
    });
  });
}
