import 'package:equatable/equatable.dart';
import '../../../../core/value_objects/money.dart';
import 'transaction.dart';

class DayGroupedTransactions extends Equatable {
  final DateTime date;
  final List<Transaction> transactions;
  final Money netTotal;

  const DayGroupedTransactions({
    required this.date,
    required this.transactions,
    required this.netTotal,
  });

  static List<DayGroupedTransactions> group(List<Transaction> transactions) {
    if (transactions.isEmpty) return const [];

    final Map<DateTime, List<Transaction>> map = {};
    for (final txn in transactions) {
      final dayKey = DateTime.utc(txn.date.year, txn.date.month, txn.date.day);
      map.putIfAbsent(dayKey, () => []).add(txn);
    }

    final sortedDays = map.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // Descending order (newest day first)

    return sortedDays.map((day) {
      final dayTxns = map[day]!;
      dayTxns.sort((a, b) {
        final cmp = b.date.compareTo(a.date);
        if (cmp != 0) return cmp;
        return b.createdAt.compareTo(a.createdAt);
      });

      int netMinorUnits = 0;
      String? firstCurrency;
      for (final txn in dayTxns) {
        firstCurrency ??= txn.amount.currencyCode;
        if (txn.type == TransactionType.income) {
          netMinorUnits += txn.amount.minorUnits;
        } else if (txn.type == TransactionType.expense) {
          netMinorUnits -= txn.amount.minorUnits;
        }
      }

      return DayGroupedTransactions(
        date: day,
        transactions: dayTxns,
        netTotal: Money(netMinorUnits, firstCurrency ?? Money.defaultCurrency),
      );
    }).toList();
  }

  @override
  List<Object?> get props => [date, transactions, netTotal];
}
