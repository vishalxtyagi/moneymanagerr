import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/category_model.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/services/filter_service.dart';
import 'package:moneymanager/services/navigation_service.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:moneymanager/widgets/common/text_field.dart';
import 'package:moneymanager/widgets/common/button.dart';
import 'package:moneymanager/widgets/common/filter_chip.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  FilterState _filterState = const FilterState();
  List<TransactionModel> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _applyFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (position.maxScrollExtent - position.pixels < 400) {
      final uid = context.read<AuthProvider>().user?.uid;
      final provider = context.read<TransactionProvider>();

      if (uid != null && provider.hasMore) {
        provider.loadMore(uid);
      }
    }
  }

  void _applyFilters() {
    final provider = context.read<TransactionProvider>();
    _filteredTransactions = provider.filterTransactions(
      type: _filterState.type,
      category: _filterState.category,
      dateRange: _filterState.dateRange,
      query: _filterState.query,
    );
    setState(() {});
  }

  void _updateFilter(FilterState newState) {
    _filterState = newState;
    _applyFilters();
  }

  void _clearAllFilters() {
    _searchController.clear();
    _updateFilter(FilterService.clearAll(_filterState));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
        actions: [
          if (_filterState.hasActiveFilters)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearAllFilters,
              tooltip: 'Clear all filters',
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_alt),
                onPressed: () => _showFilterDialog(context),
                tooltip: 'Filter transactions',
              ),
              if (_filterState.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF44336),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              label: 'Search',
              hint: 'Search transactions...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              showClearButton: true,
              onChanged: (value) {
                _updateFilter(FilterService.setQuery(_filterState, value));
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                if (_filteredTransactions.isEmpty &&
                    transactionProvider.all.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_filteredTransactions.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long,
                    title: _filterState.hasActiveFilters
                        ? 'No transactions match your filters'
                        : 'No transactions found',
                    subtitle: _filterState.hasActiveFilters
                        ? 'Try adjusting your filters'
                        : 'Start by adding your first transaction',
                    action: _filterState.hasActiveFilters
                        ? AppButton(
                            text: 'Clear Filters',
                            type: ButtonType.outlined,
                            onPressed: _clearAllFilters,
                          )
                        : null,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredTransactions.length +
                      (transactionProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= _filteredTransactions.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final transaction = _filteredTransactions[index];
                    return Selector<CategoryProvider, CategoryModel>(
                      selector: (_, provider) => provider.getCategoryByName(
                        transaction.category,
                        isIncome: transaction.type == TransactionType.income,
                      ),
                      builder: (_, category, __) => TransactionItem(
                        transaction: transaction,
                        category: category,
                        onTap: () {
                          NavigationService.openEditTransactionDrawer(
                              context, transaction);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        currentState: _filterState,
        onApply: _updateFilter,
      ),
    );
  }
}

class _FilterDialog extends StatefulWidget {
  final FilterState currentState;
  final Function(FilterState) onApply;

  const _FilterDialog({
    required this.currentState,
    required this.onApply,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late FilterState _tempState;

  @override
  void initState() {
    super.initState();
    _tempState = widget.currentState;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Transactions'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppFilterChip(
                    label: 'All',
                    isSelected: _tempState.type == TransactionType.all,
                    onTap: () => setState(() {
                      _tempState = FilterService.setType(
                          _tempState, TransactionType.all);
                    }),
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppFilterChip(
                    label: 'Income',
                    isSelected: _tempState.type == TransactionType.income,
                    onTap: () => setState(() {
                      _tempState = FilterService.setType(
                          _tempState, TransactionType.income);
                    }),
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppFilterChip(
                    label: 'Expense',
                    isSelected: _tempState.type == TransactionType.expense,
                    onTap: () => setState(() {
                      _tempState = FilterService.setType(
                          _tempState, TransactionType.expense);
                    }),
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_tempState.type != TransactionType.all) ...[
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<CategoryProvider>(
                builder: (context, catProvider, _) {
                  final isIncome = _tempState.type == TransactionType.income;
                  final categories = isIncome
                      ? catProvider.incomeCategories
                      : catProvider.expenseCategories;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _tempState.category,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map((c) => DropdownMenuItem<String?>(
                                value: c.name,
                                child: Text(c.name),
                              ))
                        ],
                        onChanged: (val) => setState(() {
                          _tempState =
                              FilterService.setCategory(_tempState, val);
                        }),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_tempState.dateRange != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.date_range,
                        color: Color(0xFF4CAF50), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormat('MMM dd, yyyy').format(_tempState.dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_tempState.dateRange!.end)}',
                        style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear,
                          color: Color(0xFF4CAF50), size: 20),
                      onPressed: () => setState(() {
                        _tempState =
                            FilterService.setDateRange(_tempState, null);
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            AppButton(
              text: _tempState.dateRange == null
                  ? 'Select Date Range'
                  : 'Change Date Range',
              icon: Icons.date_range,
              type: ButtonType.outlined,
              onPressed: _selectDateRange,
              width: double.infinity,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          text: 'Apply',
          type: ButtonType.primary,
          onPressed: () {
            widget.onApply(_tempState);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _tempState.dateRange,
    );

    if (picked != null) {
      setState(() {
        _tempState = FilterService.setDateRange(_tempState, picked);
      });
    }
  }
}
