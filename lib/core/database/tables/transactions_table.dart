import 'package:drift/drift.dart';
import 'accounts_table.dart';
import 'categories_table.dart';

@DataClassName('TransactionRow')
class Transactions extends Table {
  TextColumn get id => text()();
  @ReferenceName('accountTransactions')
  TextColumn get accountId => text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  TextColumn get transactionType => text()();
  IntColumn get amountMinorUnits => integer()();
  @ReferenceName('categoryTransactions')
  TextColumn get categoryId => text().nullable().references(Categories, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('destinationAccountTransactions')
  TextColumn get destinationAccountId => text().nullable().references(Accounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get transactionDate => integer()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
