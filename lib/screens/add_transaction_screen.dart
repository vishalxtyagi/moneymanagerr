import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/models/category_model.dart';
import 'package:moneymanager/core/models/transaction_model.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/providers/category_provider.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/core/services/notification_service.dart';
import 'package:moneymanager/widgets/widgets.dart';
import 'package:provider/provider.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _category; // Changed to nullable
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();

    // Load categories for the current user
    final categoryProvider = Provider.of<CategoryProvider>(context, listen: false);
    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId != null) {
      categoryProvider.load(userId);
    }

    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _date = widget.transaction!.date;
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _noteController.text = widget.transaction!.note ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // Helper method to ensure category is valid
  void _ensureValidCategory(List<CategoryModel> categories) {
    if (_category == null || !categories.contains(_category)) {
      if (categories.isNotEmpty) {
        _category = categories.first.name; // Set to first category if available
      }
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

    final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(context, listen: false);

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
        if (_type == 'expense' && amount >= 1000) {
          await notificationService.showLargeExpenseNotification(
            amount: amount,
            threshold: 1000,
          );
        }

        // Check for break-even balance notification
        if (transactionProvider.isNearBreakEven()) {
          await notificationService.showBreakEvenNotification(
            currentBalance: transactionProvider.getBalance(),
            threshold: 100,
          );
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.transaction == null
                ? 'Transaction added successfully'
                : 'Transaction updated successfully'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving transaction: $e')),
        );
      }
    }
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;

    final userId = Provider.of<AuthProvider>(context, listen: false).user?.uid;
    if (userId == null) return;

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final transactionProvider = Provider.of<TransactionProvider>(context, listen: false);

      try {
        await transactionProvider.remove(widget.transaction!.id, userId);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction deleted successfully'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting transaction: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submit,
          ),
        ],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
          final expenseCategories = categoryProvider.expenseCategories;
          final incomeCategories = categoryProvider.incomeCategories;
          final currentCategories = _type == 'expense' ? expenseCategories : incomeCategories;

          // Ensure category is valid whenever categories or type changes
          _ensureValidCategory(currentCategories);

          return SingleChildScrollView(
            padding: EdgeInsets.all(isWeb ? 32 : 20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type Selector
                      const SimpleHeader(title: 'Transaction Type'),
                      TransactionTypeSelector(
                        selectedType: _type,
                        onTypeChanged: (type) {
                          setState(() {
                            _type = type;
                            // Reset category when type changes
                            final currentCategories = _type == 'expense' ? expenseCategories : incomeCategories;
                            _ensureValidCategory(currentCategories);
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Amount
                      AppTextField(
                        label: 'Amount',
                        hint: 'Enter amount',
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Text('₹', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid amount';
                          }
                          if (double.parse(value) <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Title
                      AppTextField(
                        label: 'Label',
                        hint: 'What did you spend on?',
                        controller: _titleController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Category
                      if (currentCategories.isNotEmpty)
                        AppDropdown<String>(
                          label: 'Category',
                          value: _category,
                          items: currentCategories.map((category) => category.name).toList(),
                          getLabel: (category) => category,
                          onChanged: (value) {
                            setState(() {
                              _category = value;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a category';
                            }
                            return null;
                          },
                        )
                      else
                        const AppCard(
                          padding: EdgeInsets.all(16),
                          child: Text('No categories available'),
                        ),
                      const SizedBox(height: 24),

                      // Date
                      AppTextField(
                        label: 'Date',
                        controller: TextEditingController(
                          text: DateFormat('EEEE, MMM dd, yyyy').format(_date),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                        suffixIcon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 24),

                      // Note
                      AppTextField(
                        label: 'Note (Optional)',
                        hint: 'Add a note about this transaction...',
                        controller: _noteController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      AppButton(
                        text: widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
                        onPressed: currentCategories.isNotEmpty ? _submit : null,
                        width: double.infinity,
                        size: ButtonSize.large,
                        type: ButtonType.primary,
                      ),
                      const SizedBox(height: 10),

                      // Delete Button
                      if (widget.transaction != null)
                        AppButton(
                          text: 'Delete Transaction',
                          onPressed: _deleteTransaction,
                          width: double.infinity,
                          size: ButtonSize.large,
                          type: ButtonType.error,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}