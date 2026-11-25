import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/temporal/date_normalizer.dart';
import '../../../../core/value_objects/money.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final AppDatabase database;

  TransactionRepositoryImpl(this.database);

  @override
  Future<void> createTransaction(Transaction transaction) async {
    try {
      await database.transaction(() async {
        await _applyTransactionBalances(transaction);

        final normalizedDate = DateNormalizer.toUtcCalendarDate(transaction.date);

        await database.into(database.transactions).insert(
              TransactionsCompanion.insert(
                id: transaction.id,
                accountId: transaction.accountId,
                transactionType: transaction.type.name,
                amountMinorUnits: transaction.amount.minorUnits,
                currencyCode: Value(transaction.currencyCode),
                originalAmountMinorUnits: Value(transaction.originalAmount?.minorUnits),
                originalCurrencyCode: Value(transaction.originalAmount?.currencyCode),
                exchangeRateScaled: Value(transaction.exchangeRateScaled),
                categoryId: Value(transaction.categoryId),
                destinationAccountId: Value(transaction.destinationAccountId),
                transactionDate: normalizedDate.millisecondsSinceEpoch,
                note: Value(transaction.note),
                createdAt: transaction.createdAt.millisecondsSinceEpoch,
              ),
            );
      });
    } catch (e) {
      if (e is DomainFailure) rethrow;
      final errorStr = e.toString();
      if (errorStr.contains('FOREIGN KEY') || errorStr.contains('787')) {
        throw const AccountNotFoundFailure('Referenced account was not found.');
      }
      throw DatabaseFailure(errorStr);
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    try {
      await database.transaction(() async {
        final txRow = await (database.select(database.transactions)
              ..where((tbl) => tbl.id.equals(transaction.id)))
            .getSingleOrNull();
        if (txRow == null) {
          throw const DatabaseFailure('Transaction not found to update.');
        }

        // 1. Revert previous balances
        await _revertTransactionBalances(txRow);

        // 2. Apply new balances
        await _applyTransactionBalances(transaction);

        // 3. Update transaction row
        final normalizedDate = DateNormalizer.toUtcCalendarDate(transaction.date);
        await (database.update(database.transactions)
              ..where((tbl) => tbl.id.equals(transaction.id)))
            .write(
          TransactionsCompanion(
            accountId: Value(transaction.accountId),
            transactionType: Value(transaction.type.name),
            amountMinorUnits: Value(transaction.amount.minorUnits),
            currencyCode: Value(transaction.currencyCode),
            originalAmountMinorUnits: Value(transaction.originalAmount?.minorUnits),
            originalCurrencyCode: Value(transaction.originalAmount?.currencyCode),
            exchangeRateScaled: Value(transaction.exchangeRateScaled),
            categoryId: Value(transaction.categoryId),
            destinationAccountId: Value(transaction.destinationAccountId),
            transactionDate: Value(normalizedDate.millisecondsSinceEpoch),
            note: Value(transaction.note),
          ),
        );
      });
    } catch (e) {
      if (e is DomainFailure) rethrow;
      final errorStr = e.toString();
      if (errorStr.contains('FOREIGN KEY') || errorStr.contains('787')) {
        throw const AccountNotFoundFailure('Referenced account was not found.');
      }
      throw DatabaseFailure(errorStr);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await database.transaction(() async {
        final txRow = await (database.select(database.transactions)
              ..where((tbl) => tbl.id.equals(id)))
            .getSingleOrNull();
        if (txRow == null) return;

        // 1. Revert previous balances
        await _revertTransactionBalances(txRow);

        // 2. Delete transaction row
        await (database.delete(database.transactions)
              ..where((tbl) => tbl.id.equals(id)))
            .go();
      });
    } catch (e) {
      if (e is DomainFailure) rethrow;
      throw DatabaseFailure(e.toString());
    }
  }

  Future<void> _revertTransactionBalances(TransactionRow txRow) async {
    final accountRow = await (database.select(database.accounts)
          ..where((tbl) => tbl.id.equals(txRow.accountId)))
        .getSingleOrNull();
    if (accountRow == null) {
      throw const AccountNotFoundFailure('Associated account was not found.');
    }

    int revertedBalance = accountRow.currentBalanceMinorUnits;
    if (txRow.transactionType == TransactionType.expense.name) {
      revertedBalance += txRow.amountMinorUnits;
    } else if (txRow.transactionType == TransactionType.income.name) {
      revertedBalance -= txRow.amountMinorUnits;
    } else if (txRow.transactionType == TransactionType.transfer.name) {
      revertedBalance += txRow.amountMinorUnits;
      if (txRow.destinationAccountId != null) {
        final destRow = await (database.select(database.accounts)
              ..where((tbl) => tbl.id.equals(txRow.destinationAccountId!)))
            .getSingleOrNull();
        if (destRow != null) {
          final destDeductMinor = _calculateDestinationTransferRevert(txRow, accountRow, destRow);
          await (database.update(database.accounts)
                ..where((tbl) => tbl.id.equals(destRow.id)))
              .write(
            AccountsCompanion(
              currentBalanceMinorUnits:
                  Value(destRow.currentBalanceMinorUnits - destDeductMinor),
            ),
          );
        }
      }
    }

    await (database.update(database.accounts)
          ..where((tbl) => tbl.id.equals(accountRow.id)))
        .write(
      AccountsCompanion(
        currentBalanceMinorUnits: Value(revertedBalance),
      ),
    );
  }

  int _calculateDestinationTransferRevert(
    TransactionRow txRow,
    AccountRow sourceAccount,
    AccountRow destAccount,
  ) {
    if (destAccount.currencyCode.toUpperCase() == sourceAccount.currencyCode.toUpperCase()) {
      return txRow.amountMinorUnits;
    }
    if (txRow.originalAmountMinorUnits != null &&
        txRow.originalCurrencyCode?.toUpperCase() == destAccount.currencyCode.toUpperCase()) {
      return txRow.originalAmountMinorUnits!;
    }
    if (txRow.exchangeRateScaled != null) {
      final converted = Money.convert(
        from: Money(txRow.amountMinorUnits, txRow.currencyCode),
        toCurrency: destAccount.currencyCode,
        rateScaled: txRow.exchangeRateScaled!,
      );
      return converted.minorUnits;
    }
    return txRow.amountMinorUnits;
  }

  int _calculateDestinationTransferCredit(
    Transaction transaction,
    AccountRow sourceAccount,
    AccountRow destAccount,
  ) {
    if (destAccount.currencyCode.toUpperCase() == sourceAccount.currencyCode.toUpperCase()) {
      return transaction.amount.minorUnits;
    }
    if (transaction.originalAmount != null &&
        transaction.originalAmount!.currencyCode.toUpperCase() == destAccount.currencyCode.toUpperCase()) {
      return transaction.originalAmount!.minorUnits;
    }
    if (transaction.exchangeRateScaled != null) {
      final converted = Money.convert(
        from: transaction.amount,
        toCurrency: destAccount.currencyCode,
        rateScaled: transaction.exchangeRateScaled!,
      );
      return converted.minorUnits;
    }
    return transaction.amount.minorUnits;
  }

  Future<void> _applyTransactionBalances(Transaction transaction) async {
    final accountRow = await (database.select(database.accounts)
          ..where((tbl) => tbl.id.equals(transaction.accountId)))
        .getSingleOrNull();

    if (accountRow == null) {
      throw const AccountNotFoundFailure('Source account was not found.');
    }

    AccountRow? destAccount;
    if (transaction.type == TransactionType.transfer) {
      if (transaction.destinationAccountId == null ||
          transaction.destinationAccountId == transaction.accountId) {
        throw const SameSourceAndDestinationAccountFailure();
      }

      destAccount = await (database.select(database.accounts)
            ..where((tbl) => tbl.id.equals(transaction.destinationAccountId!)))
          .getSingleOrNull();

      if (destAccount == null) {
        throw const AccountNotFoundFailure('Destination account was not found.');
      }

      final sourceAccountType = AccountType.fromString(accountRow.accountType);
      if (sourceAccountType != AccountType.creditCard &&
          accountRow.currentBalanceMinorUnits < transaction.amount.minorUnits) {
        throw const InsufficientFundsFailure();
      }
    }

    int newBalanceMinorUnits = accountRow.currentBalanceMinorUnits;
    if (transaction.type == TransactionType.expense) {
      newBalanceMinorUnits -= transaction.amount.minorUnits;
    } else if (transaction.type == TransactionType.income) {
      newBalanceMinorUnits += transaction.amount.minorUnits;
    } else if (transaction.type == TransactionType.transfer && destAccount != null) {
      final targetDest = destAccount;
      final destCreditMinor = _calculateDestinationTransferCredit(transaction, accountRow, targetDest);
      newBalanceMinorUnits -= transaction.amount.minorUnits;
      await (database.update(database.accounts)
            ..where((tbl) => tbl.id.equals(targetDest.id)))
          .write(
        AccountsCompanion(
          currentBalanceMinorUnits:
              Value(targetDest.currentBalanceMinorUnits + destCreditMinor),
        ),
      );
    }

    await (database.update(database.accounts)
          ..where((tbl) => tbl.id.equals(accountRow.id)))
        .write(
      AccountsCompanion(
        currentBalanceMinorUnits: Value(newBalanceMinorUnits),
      ),
    );
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
    final rawDate = DateTime.fromMillisecondsSinceEpoch(row.transactionDate, isUtc: true);
    final normalizedDate = DateNormalizer.toUtcCalendarDate(rawDate);
    final originalAmount = row.originalAmountMinorUnits != null && row.originalCurrencyCode != null
        ? Money(row.originalAmountMinorUnits!, row.originalCurrencyCode!)
        : null;

    return Transaction(
      id: row.id,
      accountId: row.accountId,
      type: TransactionType.fromString(row.transactionType),
      amount: Money(row.amountMinorUnits, row.currencyCode),
      originalAmount: originalAmount,
      exchangeRateScaled: row.exchangeRateScaled,
      categoryId: row.categoryId,
      destinationAccountId: row.destinationAccountId,
      date: normalizedDate,
      note: row.note,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }
}
