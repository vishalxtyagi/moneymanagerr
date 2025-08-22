import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/models/category_model.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:provider/provider.dart';
import 'package:moneymanager/utils/category_util.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';

class CategoryManagerScreen extends StatefulWidget {
  const CategoryManagerScreen({super.key});

  @override
  State<CategoryManagerScreen> createState() => _CategoryManagerScreenState();
}

class _CategoryManagerScreenState extends State<CategoryManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      context.read<CategoryProvider>().load(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Categories',
            style: TextStyle(
                overflow: TextOverflow.ellipsis,
                color: Colors.white,
                fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Expenses'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: context.isDesktop
          ? _DesktopLayout(tabController: _tabController)
          : _MobileLayout(tabController: _tabController),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  final TabController tabController;

  const _DesktopLayout({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: TabBarView(
        controller: tabController,
        children: [
          _CategoryGridView(isIncome: false, tabController: tabController),
          _CategoryGridView(isIncome: true, tabController: tabController),
        ],
      ),
    );
  }
}

class _MobileLayout extends StatelessWidget {
  final TabController tabController;

  const _MobileLayout({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: tabController,
      children: [
        _CategoryList(isIncome: false, tabController: tabController),
        _CategoryList(isIncome: true, tabController: tabController),
      ],
    );
  }
}

class _CategoryGridView extends StatelessWidget {
  final bool isIncome;
  final TabController tabController;

  const _CategoryGridView(
      {required this.isIncome, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Selector<CategoryProvider, List<CategoryModel>>(
      selector: (_, provider) =>
          isIncome ? provider.incomeCategories : provider.expenseCategories,
      builder: (context, categories, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate number of columns based on available width
              double availableWidth = constraints.maxWidth;
              int columns = (availableWidth / 200).floor().clamp(1, 4);
              double cardWidth =
                  (availableWidth - (columns - 1) * 16) / columns;

              return Column(
                children: [
                  if (categories.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: AppEmptyState(
                        icon: Iconsax.category,
                        title: 'No categories',
                        subtitle: 'Add your first category below',
                      ),
                    ),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Add category card - always show
                      SizedBox(
                        width: cardWidth,
                        child: _AddCategoryCard(isIncome: isIncome),
                      ),
                      // Existing categories
                      ...categories.map((category) {
                        return SizedBox(
                          width: cardWidth,
                          child: _CategoryCard(category: category),
                        );
                      }),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const _CategoryCard({required this.category});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEditDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: category.color,
                  child: Icon(
                    CategoryUtil.getIconByIndex(category.iconIdx),
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.isIncome ? 'Income' : 'Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon:
                      Icon(Icons.more_vert, size: 18, color: Colors.grey[600]),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditDialog(context);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Iconsax.edit_2, size: 16),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Iconsax.trash, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        isIncome: category.isIncome,
        editingCategory: category,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteCategory(context),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context) async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    try {
      await context.read<CategoryProvider>().remove(userId, category);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _CategoryList extends StatelessWidget {
  final bool isIncome;
  final TabController tabController;

  const _CategoryList({required this.isIncome, required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Selector<CategoryProvider, List<CategoryModel>>(
      selector: (_, provider) =>
          isIncome ? provider.incomeCategories : provider.expenseCategories,
      builder: (context, categories, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length +
              2, // +1 for add button, +1 for empty state if needed
          itemBuilder: (context, i) {
            if (i == 0) {
              // Add category tile at the top
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AddCategoryTile(isIncome: isIncome),
              );
            }

            if (categories.isEmpty && i == 1) {
              // Show empty state message after add button when no categories
              return const Padding(
                padding: EdgeInsets.all(32),
                child: AppEmptyState(
                  icon: Iconsax.category,
                  title: 'No categories yet',
                  subtitle: 'Use the card above to add your first category',
                ),
              );
            }

            if (categories.isNotEmpty) {
              final categoryIndex =
                  i - 1; // -1 because first item is add button
              if (categoryIndex < categories.length) {
                final category = categories[categoryIndex];
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: categoryIndex == categories.length - 1 ? 0 : 12),
                  child: _CategoryTile(
                    key: ValueKey(category.name),
                    category: category,
                  ),
                );
              }
            }

            return const SizedBox
                .shrink(); // Return empty widget for extra items
          },
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryModel category;

  const _CategoryTile({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category.color,
          child: Icon(
            CategoryUtil.getIconByIndex(category.iconIdx),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(category.isIncome ? 'Income' : 'Expense'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showEditDialog(context),
              icon: const Icon(Iconsax.edit_2, size: 18),
              color: AppColors.primary,
            ),
            IconButton(
              onPressed: () => _showDeleteDialog(context),
              icon: const Icon(Iconsax.trash, size: 18),
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(
        isIncome: category.isIncome,
        editingCategory: category,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content:
            Text('Delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteCategory(context),
            child: const Text('Delete',
                style: TextStyle(
                    overflow: TextOverflow.ellipsis, color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(BuildContext context) async {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    try {
      await context.read<CategoryProvider>().remove(userId, category);
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class _AddCategoryCard extends StatelessWidget {
  final bool isIncome;

  const _AddCategoryCard({required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showAddDialog(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.add_circle,
                  color: AppColors.primary,
                  size: 32,
                ),
                SizedBox(height: 4),
                Text(
                  'Add Category',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(isIncome: isIncome),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  final bool isIncome;

  const _AddCategoryTile({required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      child: InkWell(
        onTap: () => _showAddDialog(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(
                Iconsax.add,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(
              'Add New Category',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            subtitle: Text(
              'Tap to create a new category',
              style: TextStyle(color: AppColors.primary),
            ),
            trailing: Icon(
              Iconsax.arrow_right_3,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(isIncome: isIncome),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final bool isIncome;
  final CategoryModel? editingCategory;

  const _CategoryDialog({required this.isIncome, this.editingCategory});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late TextEditingController _controller;
  late int _selectedIcon;
  late Color _selectedColor;
  bool _loading = false;

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFEF4444),
    Color(0xFFF97316),
    Color(0xFFF59E0B),
    Color(0xFF84CC16),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.editingCategory?.name ?? '');
    _selectedIcon = widget.editingCategory?.iconIdx ?? 0;
    _selectedColor = widget.editingCategory?.color ?? _colors[0];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;
    final dialogWidth = isDesktop ? 500.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.editingCategory != null ? 'Edit' : 'Add'} Category',
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Color:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      const colorSize = 50.0;
                      const spacing = 12.0;
                      final colorsPerRow =
                          ((availableWidth + spacing) / (colorSize + spacing))
                              .floor();

                      if (colorsPerRow >= _colors.length) {
                        // All colors fit in one row - use Row
                        return Row(
                          children: _colors.asMap().entries.map((entry) {
                            final i = entry.key;
                            final color = entry.value;
                            final isSelected = _selectedColor == color;
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: i == _colors.length - 1 ? 0 : spacing),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = color),
                                child: Container(
                                  width: colorSize,
                                  height: colorSize,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.grey[800]!, width: 3)
                                        : Border.all(
                                            color: Colors.grey[300]!, width: 2),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 24)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        // Colors don't fit in one row - use scrollable ListView
                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _colors.length,
                          itemBuilder: (context, i) {
                            final color = _colors[i];
                            final isSelected = _selectedColor == color;
                            return Padding(
                              padding: EdgeInsets.only(
                                  right: i == _colors.length - 1 ? 0 : spacing),
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedColor = color),
                                child: Container(
                                  width: colorSize,
                                  height: colorSize,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: isSelected
                                        ? Border.all(
                                            color: Colors.grey[800]!, width: 3)
                                        : Border.all(
                                            color: Colors.grey[300]!, width: 2),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 24)
                                      : null,
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Icon:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = isDesktop ? 10 : 6;
                      return GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1,
                        ),
                        itemCount: CategoryUtil.availableIcons.length,
                        itemBuilder: (context, i) {
                          final isSelected = _selectedIcon == i;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = i),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _selectedColor
                                    : Colors.grey[100],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? _selectedColor
                                      : Colors.grey[300]!,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                CategoryUtil.availableIcons[i],
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[600],
                                size: isDesktop ? 24 : 20,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _loading ? null : () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.editingCategory != null
                              ? 'Update'
                              : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name')),
      );
      return;
    }

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    setState(() => _loading = true);

    try {
      final provider = context.read<CategoryProvider>();
      final categories = widget.isIncome
          ? provider.incomeCategories
          : provider.expenseCategories;

      if (categories.any((c) =>
          c.name.toLowerCase() == name.toLowerCase() &&
          c != widget.editingCategory)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category already exists')),
        );
        setState(() => _loading = false);
        return;
      }

      if (widget.editingCategory != null) {
        await provider.remove(userId, widget.editingCategory!);
      }

      await provider.add(
          userId,
          CategoryModel(
            name: name,
            iconIdx: _selectedIcon,
            isIncome: widget.isIncome,
            color: _selectedColor,
          ));

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Category ${widget.editingCategory != null ? 'updated' : 'added'}')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
