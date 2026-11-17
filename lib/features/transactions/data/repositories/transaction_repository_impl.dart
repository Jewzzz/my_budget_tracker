import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase database;

  TransactionRepositoryImpl(this.database);

  @override
  Future<void> createTransaction(Transaction transaction) async {
    await database.transaction(() async {
      final accountRow = await (database.select(database.accounts)
            ..where((tbl) => tbl.id.equals(transaction.accountId)))
          .getSingleOrNull();

      if (accountRow == null) {
        throw const AccountNotFoundFailure();
      }

      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              id: transaction.id,
              accountId: transaction.accountId,
              transactionType: transaction.type.name,
              amountMinorUnits: transaction.amount.minorUnits,
              categoryId: Value(transaction.categoryId),
              destinationAccountId: Value(transaction.destinationAccountId),
              transactionDate: transaction.date.millisecondsSinceEpoch,
              note: Value(transaction.note),
              createdAt: transaction.createdAt.millisecondsSinceEpoch,
            ),
          );

      int newBalanceMinorUnits = accountRow.currentBalanceMinorUnits;
      if (transaction.type == TransactionType.expense) {
        newBalanceMinorUnits -= transaction.amount.minorUnits;
      } else if (transaction.type == TransactionType.income) {
        newBalanceMinorUnits += transaction.amount.minorUnits;
      } else if (transaction.type == TransactionType.transfer) {
        newBalanceMinorUnits -= transaction.amount.minorUnits;
        if (transaction.destinationAccountId != null) {
          final destAccount = await (database.select(database.accounts)
                ..where((tbl) => tbl.id.equals(transaction.destinationAccountId!)))
              .getSingleOrNull();
          if (destAccount != null) {
            await (database.update(database.accounts)
                  ..where((tbl) => tbl.id.equals(destAccount.id)))
                .write(
              AccountsCompanion(
                currentBalanceMinorUnits:
                    Value(destAccount.currentBalanceMinorUnits + transaction.amount.minorUnits),
              ),
            );
          }
        }
      }

      await (database.update(database.accounts)
            ..where((tbl) => tbl.id.equals(accountRow.id)))
          .write(
        AccountsCompanion(
          currentBalanceMinorUnits: Value(newBalanceMinorUnits),
        ),
      );
    });
  }

  @override
  Future<List<Transaction>> getTransactions({String? accountId, int? limit}) async {
    final query = database.select(database.transactions);
    if (accountId != null) {
      query.where((tbl) => tbl.accountId.equals(accountId));
    }
    query.orderBy([
      (tbl) => OrderingTerm.desc(tbl.transactionDate),
      (tbl) => OrderingTerm.desc(tbl.createdAt),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<List<Transaction>> getRecentTransactions({int limit = 5}) {
    return getTransactions(limit: limit);
  }

  @override
  Stream<List<Transaction>> watchTransactions({String? accountId, int? limit}) {
    final query = database.select(database.transactions);
    if (accountId != null) {
      query.where((tbl) => tbl.accountId.equals(accountId));
    }
    query.orderBy([
      (tbl) => OrderingTerm.desc(tbl.transactionDate),
      (tbl) => OrderingTerm.desc(tbl.createdAt),
    ]);
    if (limit != null) {
      query.limit(limit);
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Stream<List<Transaction>> watchRecentTransactions({int limit = 5}) {
    return watchTransactions(limit: limit);
  }

  @override
  Future<Transaction?> getTransactionById(String id) async {
    final row = await (database.select(database.transactions)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _toEntity(row) : null;
  }

  Transaction _toEntity(TransactionRow row) {
    return Transaction(
      id: row.id,
      accountId: row.accountId,
      type: TransactionType.fromString(row.transactionType),
      amount: Money(row.amountMinorUnits),
      categoryId: row.categoryId,
      destinationAccountId: row.destinationAccountId,
      date: DateTime.fromMillisecondsSinceEpoch(row.transactionDate, isUtc: true),
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }
}
