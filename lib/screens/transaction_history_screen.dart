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
import 'package:moneymanager/utils/context_util.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:moneymanager/widgets/common/text_field.dart';
import 'package:moneymanager/widgets/common/button.dart';
import 'package:moneymanager/widgets/common/filter_chip.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final TransactionType? initialType;
  final String? initialCategory;
  final DateTimeRange? initialDateRange;
  final String? initialQuery;

  const TransactionHistoryScreen({
    super.key,
    this.initialType,
    this.initialCategory,
    this.initialDateRange,
    this.initialQuery,
  });

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
    _initializeFilters();
    _applyFilters();
  }

  void _initializeFilters() {
    _filterState = FilterState(
      type: widget.initialType ?? TransactionType.all,
      category: widget.initialCategory,
      dateRange: widget.initialDateRange,
      query: widget.initialQuery ?? '',
    );

    if (widget.initialQuery?.isNotEmpty == true) {
      _searchController.text = widget.initialQuery!;
    }
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
      body: context.isDesktop
          ? _DesktopTransactionLayout(
              filterState: _filterState,
              filteredTransactions: _filteredTransactions,
              searchController: _searchController,
              scrollController: _scrollController,
              onFilterUpdate: _updateFilter,
              onClearFilters: _clearAllFilters,
            )
          : _MobileTransactionLayout(
              filterState: _filterState,
              filteredTransactions: _filteredTransactions,
              searchController: _searchController,
              scrollController: _scrollController,
              onFilterUpdate: _updateFilter,
              onClearFilters: _clearAllFilters,
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

class _DesktopTransactionLayout extends StatelessWidget {
  final FilterState filterState;
  final List<TransactionModel> filteredTransactions;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final Function(FilterState) onFilterUpdate;
  final VoidCallback onClearFilters;

  const _DesktopTransactionLayout({
    required this.filterState,
    required this.filteredTransactions,
    required this.searchController,
    required this.scrollController,
    required this.onFilterUpdate,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar with filters
          SizedBox(
            width: 280,
            child: Card(
              margin: const EdgeInsets.only(top: 16, bottom: 16, right: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _FilterSidebar(
                  filterState: filterState,
                  onFilterUpdate: onFilterUpdate,
                  onClearFilters: onClearFilters,
                ),
              ),
            ),
          ),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppTextField(
                    label: 'Search',
                    hint: 'Search transactions...',
                    controller: searchController,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    showClearButton: true,
                    onChanged: (value) {
                      onFilterUpdate(
                          FilterService.setQuery(filterState, value));
                    },
                  ),
                ),
                // Transaction grid
                Expanded(
                  child: _TransactionGrid(
                    filteredTransactions: filteredTransactions,
                    scrollController: scrollController,
                    filterState: filterState,
                    onClearFilters: onClearFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileTransactionLayout extends StatelessWidget {
  final FilterState filterState;
  final List<TransactionModel> filteredTransactions;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final Function(FilterState) onFilterUpdate;
  final VoidCallback onClearFilters;

  const _MobileTransactionLayout({
    required this.filterState,
    required this.filteredTransactions,
    required this.searchController,
    required this.scrollController,
    required this.onFilterUpdate,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: AppTextField(
            label: 'Search',
            hint: 'Search transactions...',
            controller: searchController,
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            showClearButton: true,
            onChanged: (value) {
              onFilterUpdate(FilterService.setQuery(filterState, value));
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _TransactionList(
            filteredTransactions: filteredTransactions,
            scrollController: scrollController,
            filterState: filterState,
            onClearFilters: onClearFilters,
          ),
        ),
      ],
    );
  }
}

class _FilterSidebar extends StatelessWidget {
  final FilterState filterState;
  final Function(FilterState) onFilterUpdate;
  final VoidCallback onClearFilters;

  const _FilterSidebar({
    required this.filterState,
    required this.onFilterUpdate,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (filterState.hasActiveFilters)
              TextButton(
                onPressed: onClearFilters,
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Type filter
        const Text(
          'Type',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            AppFilterChip(
              label: 'All',
              isSelected: filterState.type == TransactionType.all,
              onTap: () => onFilterUpdate(
                FilterService.setType(filterState, TransactionType.all),
              ),
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            AppFilterChip(
              label: 'Income',
              isSelected: filterState.type == TransactionType.income,
              onTap: () => onFilterUpdate(
                FilterService.setType(filterState, TransactionType.income),
              ),
              color: AppColors.success,
            ),
            const SizedBox(height: 4),
            AppFilterChip(
              label: 'Expense',
              isSelected: filterState.type == TransactionType.expense,
              onTap: () => onFilterUpdate(
                FilterService.setType(filterState, TransactionType.expense),
              ),
              color: AppColors.error,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Date range
        const Text(
          'Date Range',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Column(
          children: [
            AppFilterChip(
              label: 'All Time',
              isSelected: filterState.dateRange == null,
              onTap: () => onFilterUpdate(
                FilterService.setDateRange(filterState, null),
              ),
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            AppFilterChip(
              label: 'This Week',
              isSelected: _isCurrentWeek(filterState.dateRange),
              onTap: () => onFilterUpdate(
                FilterService.setDateRange(filterState, _getCurrentWeek()),
              ),
              color: AppColors.primary,
            ),
            const SizedBox(height: 4),
            AppFilterChip(
              label: 'This Month',
              isSelected: _isCurrentMonth(filterState.dateRange),
              onTap: () => onFilterUpdate(
                FilterService.setDateRange(filterState, _getCurrentMonth()),
              ),
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  bool _isCurrentWeek(DateTimeRange? range) {
    if (range == null) return false;
    final currentWeek = _getCurrentWeek();
    return range.start.isAtSameMomentAs(currentWeek.start) &&
        range.end.isAtSameMomentAs(currentWeek.end);
  }

  bool _isCurrentMonth(DateTimeRange? range) {
    if (range == null) return false;
    final currentMonth = _getCurrentMonth();
    return range.start.isAtSameMomentAs(currentMonth.start) &&
        range.end.isAtSameMomentAs(currentMonth.end);
  }

  DateTimeRange _getCurrentWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    return DateTimeRange(
      start: DateTime(weekStart.year, weekStart.month, weekStart.day),
      end: DateTime(weekEnd.year, weekEnd.month, weekEnd.day, 23, 59, 59),
    );
  }

  DateTimeRange _getCurrentMonth() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateTimeRange(start: monthStart, end: monthEnd);
  }
}

class _TransactionGrid extends StatelessWidget {
  final List<TransactionModel> filteredTransactions;
  final ScrollController scrollController;
  final FilterState filterState;
  final VoidCallback onClearFilters;

  const _TransactionGrid({
    required this.filteredTransactions,
    required this.scrollController,
    required this.filterState,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (filteredTransactions.isEmpty && transactionProvider.all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredTransactions.isEmpty) {
          return AppEmptyState(
            icon: Icons.receipt_long,
            title: filterState.hasActiveFilters
                ? 'No transactions match your filters'
                : 'No transactions found',
            subtitle: filterState.hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Start by adding your first transaction',
            action: filterState.hasActiveFilters
                ? AppButton(
                    text: 'Clear Filters',
                    type: ButtonType.outlined,
                    onPressed: onClearFilters,
                  )
                : null,
          );
        }

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredTransactions.length +
              (transactionProvider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= filteredTransactions.length) {
              return const Card(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final transaction = filteredTransactions[index];
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
    );
  }
}

class _TransactionList extends StatelessWidget {
  final List<TransactionModel> filteredTransactions;
  final ScrollController scrollController;
  final FilterState filterState;
  final VoidCallback onClearFilters;

  const _TransactionList({
    required this.filteredTransactions,
    required this.scrollController,
    required this.filterState,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (filteredTransactions.isEmpty && transactionProvider.all.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (filteredTransactions.isEmpty) {
          return AppEmptyState(
            icon: Icons.receipt_long,
            title: filterState.hasActiveFilters
                ? 'No transactions match your filters'
                : 'No transactions found',
            subtitle: filterState.hasActiveFilters
                ? 'Try adjusting your filters'
                : 'Start by adding your first transaction',
            action: filterState.hasActiveFilters
                ? AppButton(
                    text: 'Clear Filters',
                    type: ButtonType.outlined,
                    onPressed: onClearFilters,
                  )
                : null,
          );
        }

        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredTransactions.length +
              (transactionProvider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= filteredTransactions.length) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final transaction = filteredTransactions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Selector<CategoryProvider, CategoryModel>(
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
              ),
            );
          },
        );
      },
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
