import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/presentation/components/app_card.dart';
import '../../../../core/presentation/components/app_empty_state.dart';
import '../../../../core/presentation/components/category_icon_badge.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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

  void _openCategoryDialog({Category? existingCategory, CategoryType? defaultType}) {
    final cubit = context.read<CategoriesCubit>();
    final isEditing = existingCategory != null;
    final nameController = TextEditingController(text: existingCategory?.name ?? '');
    CategoryType selectedType = existingCategory?.type ?? defaultType ?? CategoryType.expense;
    String selectedIcon = existingCategory?.icon ?? availableIcons.first;
    int selectedColor = existingCategory?.color ?? availableColors.first;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
            title: Text(isEditing ? 'Edit Category' : 'New Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Category Name',
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.mdBorder,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!isEditing) ...[
                    const Text('Type', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const Text('Icon', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: availableIcons.map((iconName) {
                      final isSelected = iconName == selectedIcon;
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        onTap: () => setDialogState(() => selectedIcon = iconName),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          padding: const EdgeInsets.all(2),
                          child: CategoryIconBadge(
                            iconName: iconName,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: CategoryBadgeSize.medium,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('Color', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: availableColors.map((colorValue) {
                      final isSelected = colorValue == selectedColor;
                      return InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        onTap: () => setDialogState(() => selectedColor = colorValue),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: theme.colorScheme.onSurface, width: 2.5)
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
                    cubit.updateCategory(updated);
                  } else {
                    final newCategory = Category(
                      id: const Uuid().v4(),
                      name: name,
                      type: selectedType,
                      icon: selectedIcon,
                      color: selectedColor,
                      isDefault: false,
                    );
                    cubit.createCategory(newCategory);
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
    final cubit = context.read<CategoriesCubit>();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
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
              cubit.deleteCategory(category.id);
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 4),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                borderRadius: AppRadius.mdBorder,
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.mdBorder,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Expense'),
                  Tab(text: 'Income'),
                ],
              ),
            ),
          ),
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

          final expenseCategories =
              state is CategoriesLoaded ? state.expenseCategories : <Category>[];
          final incomeCategories =
              state is CategoriesLoaded ? state.incomeCategories : <Category>[];

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
          final defaultType =
              _tabController.index == 0 ? CategoryType.expense : CategoryType.income;
          _openCategoryDialog(defaultType: defaultType);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(List<Category> categories, CategoryType type) {
    if (categories.isEmpty) {
      return AppEmptyState(
        icon: Icons.category_outlined,
        title: 'No ${type.name} Categories',
        message: 'Tap the + button to add your first ${type.name.toLowerCase()} category.',
        actionLabel: 'Add Category',
        onAction: () => _openCategoryDialog(defaultType: type),
      );
    }

    final theme = Theme.of(context);

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = Color(cat.color);

        return AppCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              CategoryIconBadge(
                iconName: cat.icon,
                color: color,
                size: CategoryBadgeSize.medium,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          cat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Color Pill Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withAlpha(25),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withAlpha(60)),
                          ),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (cat.isDefault)
                      Text(
                        'Default category',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit',
                onPressed: () => _openCategoryDialog(existingCategory: cat),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: theme.colorScheme.error,
                ),
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
