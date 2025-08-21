import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/models/category_model.dart';
import 'package:moneymanager/core/services/navigation_service.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:provider/provider.dart';
import 'package:moneymanager/core/utils/category_util.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/providers/category_provider.dart';

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
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _showAddDialog(),
            icon: const Icon(Iconsax.add_copy),
          ),
        ],
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
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CategoryList(isIncome: false),
          _CategoryList(isIncome: true),
        ],
      ),
    );
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _CategoryDialog(isIncome: _tabController.index == 1),
    );
  }
}

class _CategoryList extends StatelessWidget {
  final bool isIncome;

  const _CategoryList({required this.isIncome});

  @override
  Widget build(BuildContext context) {
    return Selector<CategoryProvider, List<CategoryModel>>(
      selector: (_, provider) =>
          isIncome ? provider.incomeCategories : provider.expenseCategories,
      builder: (context, categories, _) {
        if (categories.isEmpty) {
          return const AppEmptyState(
            icon: Iconsax.category,
            title: 'No categories',
            subtitle: 'Tap + to add categories',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final category = categories[i];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: i == categories.length - 1 ? 0 : 12),
              child: _CategoryTile(
                key: ValueKey(category.name),
                category: category,
              ),
            );
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
            onPressed: () => NavigationService.goBack(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _deleteCategory(context),
            child:
                const Text('Delete', style: TextStyle(color: AppColors.error)),
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
        NavigationService.goBack(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        NavigationService.goBack(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.editingCategory != null ? 'Edit' : 'Add'} Category',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Color:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _colors.length,
                itemBuilder: (context, i) {
                  final color = _colors[i];
                  return Padding(
                    padding:
                        EdgeInsets.only(right: i == _colors.length - 1 ? 0 : 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: color,
                        child: _selectedColor == color
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text('Icon:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: CategoryUtil.availableIcons.length,
                itemBuilder: (context, i) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = i),
                    child: CircleAvatar(
                      backgroundColor: _selectedIcon == i
                          ? _selectedColor
                          : Colors.grey[200],
                      child: Icon(
                        CategoryUtil.availableIcons[i],
                        color: _selectedIcon == i
                            ? Colors.white
                            : Colors.grey[600],
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _loading ? null : () => NavigationService.goBack(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(widget.editingCategory != null ? 'Update' : 'Add'),
                ),
              ],
            ),
          ],
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
      NavigationService.goBack(context);
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
