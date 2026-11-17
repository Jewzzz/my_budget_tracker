import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_tracker/core/value_objects/money.dart';
import 'package:my_budget_tracker/features/categories/domain/entities/category.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/day_grouped_transactions.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:my_budget_tracker/features/transactions/domain/entities/transaction_filter.dart';

void main() {
  group('TransactionFilter & DayGroupedTransactions', () {
    final catGroceries = Category(
      id: 'cat-groceries',
      name: 'Groceries',
      type: CategoryType.expense,
      icon: 'shopping_cart',
      color: 0xFF10B981,
    );
    final catSalary = Category(
      id: 'cat-salary',
      name: 'Salary',
      type: CategoryType.income,
      icon: 'attach_money',
      color: 0xFF3B82F6,
    );

    final txn1 = Transaction(
      id: 'txn-1',
      accountId: 'acc-1',
      type: TransactionType.expense,
      amount: const Money(4500), // $45.00
      categoryId: catGroceries.id,
      note: 'Supermarket shopping',
      date: DateTime.utc(2026, 5, 2, 10, 0),
      createdAt: DateTime.utc(2026, 5, 2, 10, 0),
    );

    final txn2 = Transaction(
      id: 'txn-2',
      accountId: 'acc-1',
      type: TransactionType.income,
      amount: const Money(200000), // $2000.00
      categoryId: catSalary.id,
      note: 'Monthly paycheck',
      date: DateTime.utc(2026, 5, 2, 12, 0),
      createdAt: DateTime.utc(2026, 5, 2, 12, 0),
    );

    final txn3 = Transaction(
      id: 'txn-3',
      accountId: 'acc-1',
      destinationAccountId: 'acc-2',
      type: TransactionType.transfer,
      amount: const Money(30000), // $300.00
      date: DateTime.utc(2026, 5, 1, 9, 0),
      note: 'Transfer to savings',
      createdAt: DateTime.utc(2026, 5, 1, 9, 0),
    );

    final allTxns = [txn1, txn2, txn3];
    final allCats = [catGroceries, catSalary];

    test('matches transactions by search query in note or category name', () {
      final filterNote = const TransactionFilter(searchQuery: 'supermarket');
      final matchesNote = allTxns.where((t) => filterNote.matches(t, allCats)).toList();
      expect(matchesNote, [txn1]);

      final filterCat = const TransactionFilter(searchQuery: 'groceries');
      final matchesCat = allTxns.where((t) => filterCat.matches(t, allCats)).toList();
      expect(matchesCat, [txn1]);
    });

    test('matches transactions by type', () {
      final filterIncome = const TransactionFilter(type: TransactionType.income);
      final matches = allTxns.where((t) => filterIncome.matches(t, allCats)).toList();
      expect(matches, [txn2]);
    });

    test('matches transactions by accountId (source or destination)', () {
      final filterAcc2 = const TransactionFilter(accountId: 'acc-2');
      final matches = allTxns.where((t) => filterAcc2.matches(t, allCats)).toList();
      expect(matches, [txn3]);
    });

    test('matches transactions by date range', () {
      final filterDay1 = TransactionFilter(
        startDate: DateTime.utc(2026, 5, 1),
        endDate: DateTime.utc(2026, 5, 1, 23, 59, 59),
      );
      final matches = allTxns.where((t) => filterDay1.matches(t, allCats)).toList();
      expect(matches, [txn3]);
    });

    test('groups transactions by calendar day and computes daily net total', () {
      final groups = DayGroupedTransactions.group(allTxns);
      expect(groups.length, 2);

      // May 2 group (most recent)
      expect(groups[0].date.year, 2026);
      expect(groups[0].date.month, 5);
      expect(groups[0].date.day, 2);
      expect(groups[0].transactions.length, 2);
      // Net total: +200000 (income) - 4500 (expense) = +195500
      expect(groups[0].netTotal, const Money(195500));

      // May 1 group
      expect(groups[1].date.year, 2026);
      expect(groups[1].date.month, 5);
      expect(groups[1].date.day, 1);
      expect(groups[1].transactions.length, 1);
      // Net total: transfer has delta net = 0
      expect(groups[1].netTotal, Money.zero);
    });
  });
}
