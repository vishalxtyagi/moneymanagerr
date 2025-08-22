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
          // Only show filter actions for mobile view
          if (!context.isDesktop) ...[
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with clear button
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
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Transaction Type Section
          _FilterSection(
            title: 'Transaction Type',
            child: Column(
              children: [
                _FilterOptionRow(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: 'All',
                        isSelected: filterState.type == TransactionType.all,
                        onTap: () => onFilterUpdate(
                          FilterService.setType(
                              filterState, TransactionType.all),
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: 'Income',
                        isSelected: filterState.type == TransactionType.income,
                        onTap: () => onFilterUpdate(
                          FilterService.setType(
                              filterState, TransactionType.income),
                        ),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _FilterButton(
                  label: 'Expense',
                  isSelected: filterState.type == TransactionType.expense,
                  onTap: () => onFilterUpdate(
                    FilterService.setType(filterState, TransactionType.expense),
                  ),
                  color: AppColors.error,
                  fullWidth: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Section - only show when type is not 'all'
          if (filterState.type != TransactionType.all) ...[
            _FilterSection(
              title: 'Category',
              child: Consumer<CategoryProvider>(
                builder: (context, catProvider, _) {
                  final isIncome = filterState.type == TransactionType.income;
                  final categories = isIncome
                      ? catProvider.incomeCategories
                      : catProvider.expenseCategories;

                  // Check if current selected category exists in the new type's categories
                  final categoryExists = filterState.category == null ||
                      categories.any((c) => c.name == filterState.category);

                  // If category doesn't exist, we need to display it as "All Categories"
                  final displayValue =
                      categoryExists ? filterState.category : null;

                  return Container(
                    height: 48,
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: displayValue,
                        isExpanded: true,
                        hint: const Text('All Categories'),
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
                        onChanged: (val) => onFilterUpdate(
                          FilterService.setCategory(filterState, val),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Date Range Section
          _FilterSection(
            title: 'Date Range',
            child: Column(
              children: [
                // Quick date options
                _FilterOptionRow(
                  children: [
                    Expanded(
                      child: _FilterButton(
                        label: 'All Time',
                        isSelected: filterState.dateRange == null,
                        onTap: () => onFilterUpdate(
                          FilterService.setDateRange(filterState, null),
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterButton(
                        label: 'This Week',
                        isSelected: _isCurrentWeek(filterState.dateRange),
                        onTap: () => onFilterUpdate(
                          FilterService.setDateRange(
                              filterState, _getCurrentWeek()),
                        ),
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _FilterButton(
                  label: 'This Month',
                  isSelected: _isCurrentMonth(filterState.dateRange),
                  onTap: () => onFilterUpdate(
                    FilterService.setDateRange(filterState, _getCurrentMonth()),
                  ),
                  color: AppColors.primary,
                  fullWidth: true,
                ),

                const SizedBox(height: 16),

                // Custom date range display
                if (filterState.dateRange != null &&
                    !_isCurrentWeek(filterState.dateRange) &&
                    !_isCurrentMonth(filterState.dateRange)) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range,
                            color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Custom Range',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${DateFormat('MMM dd, yyyy').format(filterState.dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(filterState.dateRange!.end)}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: AppColors.primary, size: 18),
                          onPressed: () => onFilterUpdate(
                            FilterService.setDateRange(filterState, null),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Custom date range picker button
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDateRange(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      filterState.dateRange == null ||
                              _isCurrentWeek(filterState.dateRange) ||
                              _isCurrentMonth(filterState.dateRange)
                          ? 'Select Custom Range'
                          : 'Change Date Range',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: filterState.dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onFilterUpdate(FilterService.setDateRange(filterState, picked));
    }
  }

  bool _isCurrentWeek(DateTimeRange? range) {
    if (range == null) return false;
    final currentWeek = _getCurrentWeek();
    return _isSameDateRange(range, currentWeek);
  }

  bool _isCurrentMonth(DateTimeRange? range) {
    if (range == null) return false;
    final currentMonth = _getCurrentMonth();
    return _isSameDateRange(range, currentMonth);
  }

  bool _isSameDateRange(DateTimeRange range1, DateTimeRange range2) {
    return range1.start.year == range2.start.year &&
        range1.start.month == range2.start.month &&
        range1.start.day == range2.start.day &&
        range1.end.year == range2.end.year &&
        range1.end.month == range2.end.month &&
        range1.end.day == range2.end.day;
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

// Helper widget for consistent filter sections
class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

// Helper widget for consistent filter option rows
class _FilterOptionRow extends StatelessWidget {
  final List<Widget> children;

  const _FilterOptionRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(children: children);
  }
}

// Helper widget for consistent filter buttons
class _FilterButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;
  final bool fullWidth;

  const _FilterButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.color,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 36,
      child: Material(
        color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? color
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? color
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
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

        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate number of columns based on available width
              double availableWidth = constraints.maxWidth;
              int maxColumns = (availableWidth / 300).floor().clamp(1, 3);

              // Adjust columns based on number of transactions for better visual balance
              int transactionCount = filteredTransactions.length +
                  (transactionProvider.hasMore ? 1 : 0);
              int actualColumns =
                  _getOptimalColumns(transactionCount, maxColumns);

              double cardWidth =
                  (availableWidth - (actualColumns - 1) * 16) / actualColumns;

              return Column(
                children: [
                  _buildTransactionLayout(
                    context: context,
                    transactions: filteredTransactions,
                    hasMore: transactionProvider.hasMore,
                    columns: actualColumns,
                    cardWidth: cardWidth,
                    availableWidth: availableWidth,
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  /// Determines optimal number of columns based on transaction count and available space
  int _getOptimalColumns(int transactionCount, int maxColumns) {
    if (transactionCount == 0) return 1;

    // For 1-2 transactions, use single column for better visual balance
    if (transactionCount <= 2) return 1;

    // For 3-4 transactions, use 2 columns max
    if (transactionCount <= 4) return maxColumns.clamp(1, 2);

    // For more transactions, use available columns
    return maxColumns;
  }

  /// Builds the transaction layout with proper spacing and alignment
  Widget _buildTransactionLayout({
    required BuildContext context,
    required List<TransactionModel> transactions,
    required bool hasMore,
    required int columns,
    required double cardWidth,
    required double availableWidth,
  }) {
    final allItems = <Widget>[];

    // Add transaction items
    for (final transaction in transactions) {
      allItems.add(
        SizedBox(
          width: cardWidth,
          height: 102,
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
        ),
      );
    }

    // Add loading indicator if needed
    if (hasMore) {
      allItems.add(
        SizedBox(
          width: cardWidth,
          height: 102,
          child: const Card(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }

    // For small numbers of items, use a more structured layout
    if (allItems.length <= 2) {
      return Column(
        children: allItems
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: item,
                ),
              ),
            )
            .toList(),
      );
    }

    // For 3-4 items with 2 columns, use a more balanced approach
    if (allItems.length <= 4 && columns == 2) {
      return Column(
        children: [
          for (int i = 0; i < allItems.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(child: allItems[i]),
                  if (i + 1 < allItems.length) ...[
                    const SizedBox(width: 16),
                    Expanded(child: allItems[i + 1]),
                  ] else ...[
                    const SizedBox(width: 16),
                    const Expanded(
                        child: SizedBox()), // Empty space for visual balance
                  ],
                ],
              ),
            ),
        ],
      );
    }

    // For larger numbers, use the wrap layout
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: allItems,
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
