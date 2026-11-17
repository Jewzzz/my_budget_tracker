import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/category.dart';
import '../cubit/categories_cubit.dart';
import '../cubit/categories_state.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> availableIcons = [
    'shopping_cart',
    'home',
    'restaurant',
    'directions_car',
    'bolt',
    'movie',
    'local_hospital',
    'work',
    'trending_up',
    'card_giftcard',
    'school',
    'menu_book',
    'flight',
    'pets',
    'fitness_center',
    'local_cafe',
  ];

  static const List<int> availableColors = [
    0xFF10B981, // Green
    0xFF3B82F6, // Blue
    0xFFF59E0B, // Amber
    0xFF8B5CF6, // Purple
    0xFFEF4444, // Red
    0xFFEC4899, // Pink
    0xFF06B6D4, // Cyan
    0xFF84CC16, // Lime
    0xFF6366F1, // Indigo
    0xFF64748B, // Slate
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_cart':
        return Icons.shopping_cart_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'movie':
        return Icons.movie_outlined;
      case 'local_hospital':
        return Icons.local_hospital_outlined;
      case 'work':
        return Icons.work_outlined;
      case 'trending_up':
        return Icons.trending_up_outlined;
      case 'card_giftcard':
        return Icons.card_giftcard_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'flight':
        return Icons.flight_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'fitness_center':
        return Icons.fitness_center_outlined;
      case 'local_cafe':
        return Icons.local_cafe_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _openCategoryDialog({Category? existingCategory, CategoryType? defaultType}) {
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    CategoryType selectedType = existingCategory?.type ?? defaultType ?? CategoryType.expense;
    String selectedIcon = existingCategory?.icon ?? availableIcons.first;
    int selectedColor = existingCategory?.color ?? availableColors.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEditing ? 'Edit Category' : 'New Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isEditing) ...[
                    const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<CategoryType>(
                      segments: const [
                        ButtonSegment(value: CategoryType.expense, label: Text('Expense')),
                        ButtonSegment(value: CategoryType.income, label: Text('Income')),
                      ],
                      selected: {selectedType},
                      onSelectionChanged: (set) {
                        setDialogState(() => selectedType = set.first);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableIcons.map((iconName) {
                      final isSelected = iconName == selectedIcon;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedIcon = iconName),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isSelected ? Theme.of(context).colorScheme.primary.withAlpha(30) : null,
                          ),
                          child: Icon(_getIconData(iconName), size: 20),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableColors.map((colorValue) {
                      final isSelected = colorValue == selectedColor;
                      return InkWell(
                        onTap: () => setDialogState(() => selectedColor = colorValue),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  if (isEditing) {
                    final updated = existingCategory.copyWith(
                      name: name,
                      icon: selectedIcon,
                      color: selectedColor,
                    );
                    context.read<CategoriesCubit>().updateCategory(updated);
                  } else {
                    final newCategory = Category(
                      id: const Uuid().v4(),
                      name: name,
                      type: selectedType,
                      icon: selectedIcon,
                      color: selectedColor,
                      isDefault: false,
                    );
                    context.read<CategoriesCubit>().createCategory(newCategory);
                  }
                  Navigator.pop(dialogCtx);
                },
                child: Text(isEditing ? 'Save' : 'Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, Category category) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<CategoriesCubit>().deleteCategory(category.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: BlocConsumer<CategoriesCubit, CategoriesState>(
        listener: (context, state) {
          if (state is CategoriesLoaded && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CategoriesLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenseCategories = state is CategoriesLoaded ? state.expenseCategories : <Category>[];
          final incomeCategories = state is CategoriesLoaded ? state.incomeCategories : <Category>[];

          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(expenseCategories, CategoryType.expense),
              _buildCategoryList(incomeCategories, CategoryType.income),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Category',
        onPressed: () {
          final defaultType = _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
          _openCategoryDialog(defaultType: defaultType);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, CategoryType type) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'No ${type.name} categories found.',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = Color(cat.color);

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          leading: CircleAvatar(
            backgroundColor: color.withAlpha(35),
            child: Icon(_getIconData(cat.icon), color: color, size: 22),
          ),
          title: Text(
            cat.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: cat.isDefault
              ? const Text('Default category', style: TextStyle(fontSize: 12))
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: () => _openCategoryDialog(existingCategory: cat),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, cat),
              ),
            ],
          ),
        );
      },
    );
  }
}
