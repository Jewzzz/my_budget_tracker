import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({CategoryType? type});
  Stream<List<Category>> watchCategories({CategoryType? type});
  Future<Category?> getCategoryById(String id);
}
