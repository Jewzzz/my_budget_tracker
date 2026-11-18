import 'package:drift/drift.dart';
import 'accounts_table.dart';
import 'savings_goals_table.dart';

@DataClassName('GoalContributionRow')
class GoalContributions extends Table {
  TextColumn get id => text()();
  @ReferenceName('goalContributions')
  TextColumn get goalId => text().references(SavingsGoals, #id, onDelete: KeyAction.cascade)();
  @ReferenceName('accountGoalContributions')
  TextColumn get accountId => text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  IntColumn get amountMinorUnits => integer()();
  TextColumn get currencyCode => text().withDefault(const Constant('USD'))();
  IntColumn get originalAmountMinorUnits => integer().nullable()();
  IntColumn get exchangeRateScaled => integer().nullable()();
  TextColumn get contributionType => text()(); // 'deposit' | 'withdrawal'
  IntColumn get contributionDate => integer()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
