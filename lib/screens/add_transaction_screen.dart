import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final TransactionModel? transaction;

  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.onClose,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _category;
  DateTime _date = DateTime.now();

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
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    try {
      final amount = double.parse(_amountController.text);

      if (widget.transaction == null) {
        await transactionProvider.add(
          userId: userId,
          title: _titleController.text,
          amount: amount,
          date: _date,
          category: _category!,
          type: _type,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );

        // Show notification for large expenses
        if (_type == TransactionType.expense && amount >= 1000) {
          await NotificationService.showExpenseAlert(amount, 1000);
        }

        // Check for break-even balance notification
        if (transactionProvider.isNearBreakEven()) {
          await NotificationService.showBalanceWarning(
              transactionProvider.getBalance(), 100);
        }
      } else {
        final updatedTransaction = TransactionModel(
          id: widget.transaction!.id,
          userId: widget.transaction!.userId,
          title: _titleController.text,
          amount: amount,
          date: _date,
          category: _category!,
          type: _type,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          createdAt: widget.transaction!.createdAt,
          updatedAt: DateTime.now(),
        );
        await transactionProvider.update(updatedTransaction);
      }

      if (mounted) {
        // Clear form after successful submission
        _clearForm();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction == null
                ? 'Transaction added successfully'
                : 'Transaction updated successfully'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _amountController.clear();
    _noteController.clear();
    setState(() {
      _type = TransactionType.expense;
      _category = null;
      _date = DateTime.now();
    });
    _categoryNotifier.value = null;
  }

  void _close() {
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;
    
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: double.infinity,
      ),
      child: Material(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.2),
        child: Column(
          children: [
            // Header
            _HeaderSection(
              isEditing: widget.transaction != null,
              onClose: _close,
            ),
            
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type
                      const _SectionLabel(text: 'Transaction Type'),
                      const SizedBox(height: 12),
                      _TransactionTypeSelector(
                        selectedType: _type,
                        onTypeChanged: (type) {
                          setState(() {
                            _type = type;
                            _category = null;
                          });
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Amount
                      const _SectionLabel(text: 'Amount'),
                      const SizedBox(height: 8),
                      _AmountField(controller: _amountController),
                      
                      const SizedBox(height: 24),
                      
                      // Title
                      const _SectionLabel(text: 'Description'),
                      const SizedBox(height: 8),
                      _DescriptionField(
                        controller: _titleController,
                        transactionType: _type,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Category
                      const _SectionLabel(text: 'Category'),
                      const SizedBox(height: 8),
                      _CategorySelector(
                        selectedCategory: _category,
                        transactionType: _type,
                        onCategoryChanged: (category) {
                          setState(() {
                            _category = category;
                          });
                          _categoryNotifier.value = category;
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date
                      const _SectionLabel(text: 'Date'),
                      const SizedBox(height: 8),
                      _DateSelector(
                        selectedDate: _date,
                        onDateSelected: () => _selectDate(context),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Note
                      const _SectionLabel(text: 'Note (Optional)'),
                      const SizedBox(height: 8),
                      _NoteField(controller: _noteController),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action buttons - Isolated to prevent rebuilds on type change
            _IsolatedActionButtons(
              isEditing: widget.transaction != null,
              categoryNotifier: _categoryNotifier,
              onSubmit: _submit,
              onClearForm: widget.transaction == null ? _clearForm : null,
            ),
          ],
        ),
      ),
    );
  }
}

// Extracted widgets for better performance and structure

class _HeaderSection extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onClose;

  const _HeaderSection({
    required this.isEditing,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Iconsax.add_copy,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Transaction' : 'Add Transaction',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Quick and easy transaction entry',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(
                Iconsax.close_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _TransactionTypeSelector extends StatelessWidget {
  final TransactionType selectedType;
  final ValueChanged<TransactionType> onTypeChanged;

  const _TransactionTypeSelector({
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TypeButton(
              label: 'Expense',
              icon: Iconsax.arrow_down,
              color: AppColors.error,
              isSelected: selectedType == TransactionType.expense,
              onTap: () => onTypeChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _TypeButton(
              label: 'Income',
              icon: Iconsax.arrow_up,
              color: AppColors.success,
              isSelected: selectedType == TransactionType.income,
              onTap: () => onTypeChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;

  const _AmountField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: 'Enter amount',
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: Text(
            '₹',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(_AddTransactionScreenState._amountInputFormatter),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) return 'Please enter an amount';
        final v = double.tryParse(value);
        if (v == null) return 'Please enter a valid amount';
        if (v <= 0) return 'Amount must be greater than 0';
        return null;
      },
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  final TransactionType transactionType;

  const _DescriptionField({
    required this.controller,
    required this.transactionType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: transactionType == TransactionType.expense 
            ? 'What did you spend on?' 
            : 'What did you earn?',
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: (value) => (value == null || value.isEmpty) 
          ? 'Please enter a description' 
          : null,
    );
  }
}

class _CategorySelector extends StatelessWidget {
  final String? selectedCategory;
  final TransactionType transactionType;
  final ValueChanged<String?> onCategoryChanged;

  const _CategorySelector({
    required this.selectedCategory,
    required this.transactionType,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<CategoryProvider, List<dynamic>>(
      selector: (context, provider) => transactionType == TransactionType.expense
          ? provider.expenseCategories
          : provider.incomeCategories,
      builder: (context, categories, child) {
        if (categories.isEmpty) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No categories available'),
            ),
          );
        }
        
        // Auto-select first category if none selected
        if (selectedCategory == null || !categories.any((c) => c.name == selectedCategory)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onCategoryChanged(categories.first.name);
          });
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
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.name,
              child: Text(category.name),
            );
          }).toList(),
          onChanged: onCategoryChanged,
          validator: (value) => (value == null || value.isEmpty) 
              ? 'Please select a category' 
              : null,
        );
      },
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onDateSelected;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDateSelected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Iconsax.calendar,
                color: Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _AddTransactionScreenState._dateFormatter.format(selectedDate),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                Iconsax.arrow_right_3,
                color: Colors.grey.shade600,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;

  const _NoteField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add a note about this transaction...',
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
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}

class _IsolatedActionButtons extends StatelessWidget {
  final bool isEditing;
  final ValueNotifier<String?> categoryNotifier;
  final VoidCallback onSubmit;
  final VoidCallback? onClearForm;

  const _IsolatedActionButtons({
    required this.isEditing,
    required this.categoryNotifier,
    required this.onSubmit,
    this.onClearForm,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: categoryNotifier,
      builder: (context, category, child) {
        final canSubmit = category != null;
        
        return Material(
          color: Colors.grey.shade50,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canSubmit ? onSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isEditing ? 'Update Transaction' : 'Add Transaction',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (onClearForm != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: onClearForm,
                        child: Text(
                          'Clear Form',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
