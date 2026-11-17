import 'package:drift/drift.dart';
import 'categories_table.dart';

@DataClassName('BudgetRow')
class Budgets extends Table {
  TextColumn get id => text()();
  @ReferenceName('categoryBudgets')
  TextColumn get categoryId => text().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get year => integer()();
  IntColumn get month => integer()();
  IntColumn get limitMinorUnits => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {categoryId, year, month},
      ];
}
