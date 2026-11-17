import '../entities/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories({CategoryType? type});
  Stream<List<Category>> watchCategories({CategoryType? type});
  Future<Category?> getCategoryById(String id);
  Future<void> createCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
}
