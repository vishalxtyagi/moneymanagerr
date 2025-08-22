import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/utils/category_util.dart';
import 'package:moneymanager/utils/context_util.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class TransactionDrawer extends StatefulWidget {
  final VoidCallback? onClose;
  final TransactionModel? transaction;

  const TransactionDrawer({
    super.key,
    this.transaction,
    this.onClose,
  });

  @override
  State<TransactionDrawer> createState() => _TransactionDrawerState();
}

class _TransactionDrawerState extends State<TransactionDrawer> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _category;
  DateTime _date = DateTime.now();

  // Track if form has been modified
  bool _hasUnsavedChanges = false;

  // Original values for comparison
  late final String _originalTitle;
  late final String _originalAmount;
  late final String _originalNote;
  late final TransactionType _originalType;
  late final String? _originalCategory;
  late final DateTime _originalDate;

  // Notifier to avoid rebuilding action buttons when category changes
  late final ValueNotifier<String?> _categoryNotifier;

  // Precomputed values to avoid rebuilding
  static final DateFormat _dateFormatter = DateFormat('EEEE, MMM dd, yyyy');
  static final RegExp _amountInputFormatter = RegExp(r'^[0-9]*\.?[0-9]{0,2}');

  @override
  void initState() {
    super.initState();

    // Initialize category notifier
    _categoryNotifier = ValueNotifier<String?>(_category);

    // Initialize transaction values if editing
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _date = widget.transaction!.date;
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _noteController.text = widget.transaction!.note ?? '';
      _categoryNotifier.value = _category;
    }

    // Store original values
    _originalTitle = _titleController.text;
    _originalAmount = _amountController.text;
    _originalNote = _noteController.text;
    _originalType = _type;
    _originalCategory = _category;
    _originalDate = _date;

    // Add listeners to detect changes
    _titleController.addListener(_checkForChanges);
    _amountController.addListener(_checkForChanges);
    _noteController.addListener(_checkForChanges);

    _loadCategories();
  }

  @override
  void dispose() {
    _categoryNotifier.dispose();
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasChanges = _titleController.text != _originalTitle ||
        _amountController.text != _originalAmount ||
        _noteController.text != _originalNote ||
        _type != _originalType ||
        _category != _originalCategory ||
        _date != _originalDate;

    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  Future<void> _loadCategories() async {
    final categoryProvider = context.read<CategoryProvider>();
    final userId = context.read<AuthProvider>().user?.uid;

    if (userId != null) {
      await categoryProvider.load(userId);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
      _checkForChanges();
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = context.read<AuthProvider>().user?.uid;
    if (userId == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    try {
      final transactionProvider = context.read<TransactionProvider>();

      if (widget.transaction != null) {
        // Update existing transaction
        final now = DateTime.now();
        final transaction = TransactionModel(
          id: widget.transaction!.id,
          userId: userId,
          title: _titleController.text.trim(),
          amount: amount,
          type: _type,
          category: _category ?? '',
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          createdAt: widget.transaction!.createdAt,
          updatedAt: now,
        );
        await transactionProvider.update(transaction);
      } else {
        // Add new transaction
        await transactionProvider.add(
          userId: userId,
          title: _titleController.text.trim(),
          amount: amount,
          type: _type,
          category: _category ?? '',
          date: _date,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      }

      setState(() {
        _hasUnsavedChanges = false;
      });

      _close();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction != null
                ? 'Transaction updated successfully'
                : 'Transaction added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
                'You have unsaved changes. Are you sure you want to close without saving?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child:
                    const Text('Discard', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _close() async {
    final shouldClose = await _showUnsavedChangesDialog();
    if (shouldClose) {
      widget.onClose?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    final content = Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: _close,
                icon: const Icon(Iconsax.arrow_left_copy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isEditing ? 'Edit Transaction' : 'Add Transaction',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Form Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transaction Type Toggle
                  _TransactionTypeToggle(
                    type: _type,
                    onChanged: (type) {
                      setState(() {
                        _type = type;
                        _category = null;
                        _categoryNotifier.value = null;
                      });
                      _checkForChanges();
                    },
                  ),

                  const SizedBox(height: 20),

                  // Title Field
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Enter transaction title',
                    icon: Iconsax.edit,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Amount Field
                  _buildTextField(
                    controller: _amountController,
                    label: 'Amount',
                    hint: '0.00',
                    icon: Iconsax.money,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(_amountInputFormatter),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Please enter a valid amount';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Category Selection
                  _CategorySelector(
                    type: _type,
                    selectedCategory: _category,
                    categoryNotifier: _categoryNotifier,
                    onCategorySelected: (category) {
                      setState(() {
                        _category = category;
                        _categoryNotifier.value = category;
                      });
                      _checkForChanges();
                    },
                  ),

                  const SizedBox(height: 16),

                  // Date Selection
                  _buildDateSelector(context),

                  const SizedBox(height: 16),

                  // Note Field
                  _buildTextField(
                    controller: _noteController,
                    label: 'Note (Optional)',
                    hint: 'Add a note...',
                    icon: Iconsax.note,
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
        ),

        // Action Buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _close,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(isEditing ? 'Update' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldClose = await _showUnsavedChangesDialog();
          if (shouldClose && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: isEditing && context.isDesktop
          ? Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 500,
                  maxHeight: 700,
                ),
                child: content,
              ),
            )
          : Drawer(
              width: context.isDesktop ? 400 : double.infinity,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: content,
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              children: [
                const Icon(Iconsax.calendar, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  _dateFormatter.format(_date),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionTypeToggle extends StatelessWidget {
  final TransactionType type;
  final Function(TransactionType) onChanged;

  const _TransactionTypeToggle({
    required this.type,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              'Expense',
              Iconsax.trend_down,
              Colors.red,
              type == TransactionType.expense,
              () => onChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              'Income',
              Iconsax.trend_up,
              Colors.green,
              type == TransactionType.income,
              () => onChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(
    String label,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final TransactionType type;
  final String? selectedCategory;
  final ValueNotifier<String?> categoryNotifier;
  final Function(String?) onCategorySelected;

  const _CategorySelector({
    required this.type,
    required this.selectedCategory,
    required this.categoryNotifier,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Consumer<CategoryProvider>(
          builder: (context, categoryProvider, child) {
            final categories = type == TransactionType.income
                ? categoryProvider.incomeCategories
                : categoryProvider.expenseCategories;

            if (categories.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: const Text(
                  'No categories available. Add categories in Settings.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            return DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              hint: const Text('Select a category'),
              selectedItemBuilder: (context) {
                return categories.map((category) {
                  return Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryUtil.getIconByIndex(category.iconIdx),
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                }).toList();
              },
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category.name,
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CategoryUtil.getIconByIndex(category.iconIdx),
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onCategorySelected,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a category';
                }
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}
