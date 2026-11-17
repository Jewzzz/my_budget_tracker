import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/error/failures.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';

void main() {
  group('Transaction Entity Unit Tests', () {
    final validDate = DateTime.utc(2026, 5, 1, 10, 0);

    test('creates valid expense Transaction instance and supports value equality', () {
      final txn1 = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: const Money(2500), // $25.00
        categoryId: 'cat-groceries',
        date: validDate,
        note: 'Supermarket trip',
        createdAt: validDate,
      );

      final txn2 = Transaction(
        id: 'txn-1',
        accountId: 'acc-1',
        type: TransactionType.expense,
        amount: const Money(2500),
        categoryId: 'cat-groceries',
        date: validDate,
        note: 'Supermarket trip',
        createdAt: validDate,
      );

      expect(txn1, equals(txn2));
      expect(txn1.isExpense, isTrue);
      expect(txn1.isIncome, isFalse);
      expect(txn1.isTransfer, isFalse);
    });

    test('creates valid income Transaction instance', () {
      final txn = Transaction(
        id: 'txn-2',
        accountId: 'acc-1',
        type: TransactionType.income,
        amount: const Money(300000), // $3000.00
        categoryId: 'cat-salary',
        date: validDate,
        createdAt: validDate,
      );

      expect(txn.isIncome, isTrue);
      expect(txn.amount, const Money(300000));
    });

    test('enforces positive non-zero amount invariant', () {
      expect(
        () => Transaction(
          id: 'txn-bad',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: Money.zero,
          categoryId: 'cat-groceries',
          date: validDate,
          createdAt: validDate,
        ),
        throwsA(isA<InvalidTransactionAmountFailure>()),
      );

      expect(
        () => Transaction(
          id: 'txn-neg',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: const Money(-500),
          categoryId: 'cat-groceries',
          date: validDate,
          createdAt: validDate,
        ),
        throwsA(isA<InvalidTransactionAmountFailure>()),
      );
    });

    test('enforces categoryId presence for expense and income', () {
      expect(
        () => Transaction(
          id: 'txn-no-cat',
          accountId: 'acc-1',
          type: TransactionType.expense,
          amount: const Money(1500),
          categoryId: null,
          date: validDate,
          createdAt: validDate,
        ),
        throwsA(isA<MissingCategoryFailure>()),
      );

      expect(
        () => Transaction(
          id: 'txn-no-cat-inc',
          accountId: 'acc-1',
          type: TransactionType.income,
          amount: const Money(1500),
          categoryId: null,
          date: validDate,
          createdAt: validDate,
        ),
        throwsA(isA<MissingCategoryFailure>()),
      );
    });

    test('TransactionType parser parses strings accurately', () {
      expect(TransactionType.fromString('expense'), TransactionType.expense);
      expect(TransactionType.fromString('income'), TransactionType.income);
      expect(TransactionType.fromString('transfer'), TransactionType.transfer);
      expect(TransactionType.fromString('other'), TransactionType.expense);
    });
  });
}
