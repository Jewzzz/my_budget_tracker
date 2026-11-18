import 'package:drift/drift.dart';

@DataClassName('SavingsGoalRow')
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('USD'))();
  IntColumn get targetAmountMinorUnits => integer()();
  IntColumn get savedAmountMinorUnits => integer().withDefault(const Constant(0))();
  IntColumn get targetDate => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('inProgress'))();
  TextColumn get icon => text()();
  IntColumn get color => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
