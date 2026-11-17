import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final AppDatabase database;

  CategoryRepositoryImpl(this.database);

  @override
  Future<List<Category>> getCategories({CategoryType? type}) async {
    final query = database.select(database.categories);
    if (type != null) {
      query.where((tbl) => tbl.categoryType.equals(type.name));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    final rows = await query.get();
    return rows.map(_toEntity).toList();
  }

  @override
  Stream<List<Category>> watchCategories({CategoryType? type}) {
    final query = database.select(database.categories);
    if (type != null) {
      query.where((tbl) => tbl.categoryType.equals(type.name));
    }
    query.orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);
    return query.watch().map((rows) => rows.map(_toEntity).toList());
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final row = await (database.select(database.categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row != null ? _toEntity(row) : null;
  }

  @override
  Future<void> createCategory(Category category) async {
    await database.into(database.categories).insert(
      CategoriesCompanion.insert(
        id: category.id,
        name: category.name,
        categoryType: category.type.name,
        icon: category.icon,
        color: category.color,
        isDefault: Value(category.isDefault),
      ),
    );
  }

  @override
  Future<void> updateCategory(Category category) async {
    await (database.update(database.categories)..where((tbl) => tbl.id.equals(category.id))).write(
      CategoriesCompanion(
        name: Value(category.name),
        categoryType: Value(category.type.name),
        icon: Value(category.icon),
        color: Value(category.color),
      ),
    );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final category = await (database.select(database.categories)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (category == null) return;

    try {
      await (database.delete(database.categories)..where((tbl) => tbl.id.equals(id))).go();
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('FOREIGN KEY') ||
          errorStr.contains('787') ||
          errorStr.contains('19')) {
        throw const CategoryHasTransactionsFailure();
      }
      throw DatabaseFailure(errorStr);
    }
  }

  Category _toEntity(CategoryRow row) {
    return Category(
      id: row.id,
      name: row.name,
      type: CategoryType.fromString(row.categoryType),
      icon: row.icon,
      color: row.color,
      isDefault: row.isDefault,
    );
  }
}
