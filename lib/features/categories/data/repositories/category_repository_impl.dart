import 'package:drift/drift.dart';
import '../../../../core/database/app_database.dart';
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
