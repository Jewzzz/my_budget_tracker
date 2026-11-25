import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/value_objects/money.dart';
import '../../domain/entities/account.dart';
import '../../domain/repositories/account_repository.dart';

class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase database;

  AccountRepositoryImpl(this.database);

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) {
    final query = database.select(database.accounts);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<List<Account>> getAccounts({bool includeArchived = false}) async {
    final query = database.select(database.accounts);
    if (!includeArchived) {
      query.where((tbl) => tbl.isArchived.equals(false));
    }
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final row = await (database.select(database.accounts)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<void> createAccount(Account account) async {
    await database.into(database.accounts).insert(
          AccountsCompanion.insert(
            id: account.id,
            name: account.name,
            accountType: account.type.name,
            currencyCode: Value(account.currencyCode),
            initialBalanceMinorUnits: Value(account.initialBalance.minorUnits),
            currentBalanceMinorUnits: Value(account.currentBalance.minorUnits),
            isArchived: Value(account.isArchived),
            icon: account.icon,
            color: account.color,
            createdAt: account.createdAt.millisecondsSinceEpoch,
          ),
        );
  }

  @override
  Future<void> updateAccount(Account account) async {
    await (database.update(database.accounts)..where((tbl) => tbl.id.equals(account.id))).write(
      AccountsCompanion(
        name: Value(account.name),
        accountType: Value(account.type.name),
        isArchived: Value(account.isArchived),
        icon: Value(account.icon),
        color: Value(account.color),
      ),
    );
  }

  @override
  Future<void> archiveAccount(String id, bool isArchived) async {
    await (database.update(database.accounts)..where((tbl) => tbl.id.equals(id))).write(
      AccountsCompanion(
        isArchived: Value(isArchived),
      ),
    );
  }

  @override
  Future<void> deleteAccount(String id) async {
    try {
      final rowsDeleted = await (database.delete(database.accounts)..where((tbl) => tbl.id.equals(id))).go();
      if (rowsDeleted == 0) {
        throw const AccountNotFoundFailure();
      }
    } catch (e) {
      if (e is AccountNotFoundFailure) rethrow;
      final errorStr = e.toString();
      if (errorStr.contains('FOREIGN KEY') ||
          errorStr.contains('787') ||
          errorStr.contains('19')) {
        throw const AccountHasTransactionsFailure();
      }
      throw DatabaseFailure(errorStr);
    }
  }

  Account _toEntity(AccountRow row) {
    return Account(
      id: row.id,
      name: row.name,
      type: AccountType.fromString(row.accountType),
      currencyCode: row.currencyCode,
      initialBalance: Money(row.initialBalanceMinorUnits, row.currencyCode),
      currentBalance: Money(row.currentBalanceMinorUnits, row.currencyCode),
      isArchived: row.isArchived,
      icon: row.icon,
      color: row.color,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
    );
  }
}
