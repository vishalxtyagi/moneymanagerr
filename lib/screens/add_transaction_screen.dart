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
import 'package:moneymanager/widgets/common/button.dart';
import 'package:moneymanager/widgets/common/card.dart';
import 'package:moneymanager/widgets/common/dropdown.dart';
import 'package:moneymanager/widgets/common/text_field.dart';
import 'package:moneymanager/widgets/common/type_selector.dart';
import 'package:moneymanager/widgets/header/simple_header.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class AddTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _type = TransactionType.expense;
  String? _category; // Changed to nullable
  DateTime _date = DateTime.now();

  // ValueNotifiers to minimize rebuilds
  late final ValueNotifier<TransactionType> _typeVN;
  late final ValueNotifier<String?> _categoryVN;
  late final ValueNotifier<DateTime> _dateVN;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    // Load categories for the current user
    final categoryProvider =
        Provider.of<CategoryProvider>(context, listen: false);
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

    // Init notifiers from current state
    _typeVN = ValueNotifier<TransactionType>(_type);
    _categoryVN = ValueNotifier<String?>(_category);
    _dateVN = ValueNotifier<DateTime>(_date);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _typeVN.dispose();
    _categoryVN.dispose();
    _dateVN.dispose();
    super.dispose();
  }

  // Helper method to ensure category is valid
  void _ensureValidCategory(List<CategoryModel> categories) {
    if (_category == null || !categories.any((c) => c.name == _category)) {
      if (categories.isNotEmpty) {
        _category = categories.first.name; // Set to first category if available
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateVN.value,
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
    if (picked != null && picked != _dateVN.value) {
      _dateVN.value = picked;
      _date = picked; // keep in sync for any legacy reads
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
          date: _dateVN.value,
          category: _categoryVN.value!,
          type: _typeVN.value,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );

        // Show notification for large expenses
        if (_typeVN.value == TransactionType.expense && amount >= 1000) {
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
          date: _dateVN.value,
          category: _categoryVN.value!,
          type: _typeVN.value,
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
          content: const Text(
              'Are you sure you want to delete this transaction? This action cannot be undone.'),
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
      if (!mounted) return;
      final transactionProvider =
          Provider.of<TransactionProvider>(context, listen: false);

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
    super.build(context); // for keep alive
    final screenWidth = MediaQuery.sizeOf(context).width;
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
      body: Padding(
        padding: EdgeInsets.all(isWeb ? 32 : 20),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Transaction Type Selector (isolated rebuild)
                  const AppSimpleHeader(title: 'Transaction Type'),
                  RepaintBoundary(
                    child: ValueListenableBuilder<TransactionType>(
                      valueListenable: _typeVN,
                      builder: (context, type, _) {
                        return AppTypeSelector<TransactionType>(
                          selectedValue: type,
                          values: const [
                            TransactionType.expense,
                            TransactionType.income,
                          ],
                          labelBuilder: (t) =>
                              t == TransactionType.income ? 'Income' : 'Expense',
                          iconBuilder: (t) =>
                              t == TransactionType.income ? Icons.arrow_upward : Icons.arrow_downward,
                          colorBuilder: (t) =>
                              t == TransactionType.income ? AppColors.success : AppColors.error,
                          onChanged: (newType) {
                            final provider = context.read<CategoryProvider>();
                            final list = newType == TransactionType.expense
                                ? provider.expenseCategories
                                : provider.incomeCategories;
                            _typeVN.value = newType;
                            _type = newType; // optional sync
                            _categoryVN.value = list.isNotEmpty ? list.first.name : null;
                            _category = _categoryVN.value; // optional sync
                          },
                        );
                      },
                    ),
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
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]{0,2}')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter an amount';
                      final v = double.tryParse(value);
                      if (v == null) return 'Please enter a valid amount';
                      if (v <= 0) return 'Amount must be greater than 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Title (hint reacts only to type changes)
                  ValueListenableBuilder<TransactionType>(
                    valueListenable: _typeVN,
                    builder: (context, type, _) {
                      return AppTextField(
                        label: 'Label',
                        hint: type == TransactionType.expense ? 'What did you spend on?' : 'What did you earn?',
                        controller: _titleController,
                        validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Category (rebuilds only when categories or type changes)
                  ValueListenableBuilder<TransactionType>(
                    valueListenable: _typeVN,
                    builder: (context, type, _) {
                      return Selector<CategoryProvider, List<CategoryModel>>(
                        selector: (context, provider) =>
                            type == TransactionType.expense ? provider.expenseCategories : provider.incomeCategories,
                        builder: (context, categories, __) {
                          final current = _categoryVN.value;
                          final hasCurrent = current != null && categories.any((c) => c.name == current);
                          if (!hasCurrent && categories.isNotEmpty) {
                            // defer to next frame to avoid build-time setState
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _categoryVN.value = categories.first.name;
                              _category = _categoryVN.value; // optional sync
                            });
                          }
                          if (categories.isEmpty) {
                            return const AppCard(padding: EdgeInsets.all(16), child: Text('No categories available'));
                          }
                          return ValueListenableBuilder<String?>(
                            valueListenable: _categoryVN,
                            builder: (context, selected, ___) => AppDropdown<String>(
                              label: 'Category',
                              value: selected,
                              items: categories.map((c) => c.name).toList(),
                              getLabel: (v) => v,
                              onChanged: (value) => _categoryVN.value = value,
                              validator: (value) => (value == null || value.isEmpty) ? 'Please select a category' : null,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Date (rebuilds only when date changes)
                  ValueListenableBuilder<DateTime>(
                    valueListenable: _dateVN,
                    builder: (context, date, _) {
                      return AppTextField(
                        label: 'Date',
                        initialValue: DateFormat('EEEE, MMM dd, yyyy').format(date),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        prefixIcon: const Icon(Icons.calendar_today, color: AppColors.textSecondary),
                        suffixIcon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      );
                    },
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

                  // Save / Delete Buttons (enabled state reacts only to category changes)
                  RepaintBoundary(
                    child: Column(
                      children: [
                        ValueListenableBuilder<String?>(
                          valueListenable: _categoryVN,
                          builder: (context, selected, _) => AppButton(
                            text: widget.transaction == null ? 'Add Transaction' : 'Update Transaction',
                            onPressed: selected != null ? _submit : null,
                            width: double.infinity,
                            size: ButtonSize.lg,
                            type: ButtonType.primary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (widget.transaction != null)
                          AppButton(
                            text: 'Delete Transaction',
                            onPressed: _deleteTransaction,
                            width: double.infinity,
                            size: ButtonSize.lg,
                            type: ButtonType.error,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
