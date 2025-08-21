import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/category_model.dart';
import 'package:moneymanager/providers/auth_provider.dart';
import 'package:moneymanager/providers/category_provider.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/services/navigation_service.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:moneymanager/widgets/common/text_field.dart';
import 'package:moneymanager/widgets/common/button.dart';
import 'package:moneymanager/widgets/common/filter_chip.dart';
import 'package:moneymanager/widgets/states/empty_state.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final TransactionType? initialType;
  final String? initialCategory;
  final DateTimeRange? initialRange;
  final String? initialQuery;
  final bool ephemeralFilters; // Restore previous filters on dispose
  
  const TransactionHistoryScreen({
    super.key,
    this.initialType,
    this.initialCategory,
    this.initialRange,
    this.initialQuery,
    this.ephemeralFilters = false,
  });

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Store previous state for ephemeral filters
  TransactionType? _previousType;
  String? _previousCategory;
  DateTimeRange? _previousRange;
  String? _previousQuery;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _applyInitialFilters();
    _scrollController.addListener(_onScroll);
  }

  void _applyInitialFilters() {
    final provider = context.read<TransactionProvider>();
    
    // Store previous state if using ephemeral filters
    if (widget.ephemeralFilters) {
      _previousType = provider.filterType;
      _previousCategory = provider.filterCategory;
      _previousRange = provider.filterRange;
      _previousQuery = provider.searchQuery;
      
      // Clear existing filters before applying new ones
      provider.clearAllFilters();
    }
    
    // Apply initial filters
    if (widget.initialType != null) {
      provider.setTypeFilter(widget.initialType!);
    }
    provider.setRangeFilter(widget.initialRange);
    provider.setCategoryFilter(widget.initialCategory);

    if (widget.initialQuery?.isNotEmpty == true) {
      provider.setQuery(widget.initialQuery!);
      _searchController.text = widget.initialQuery!;
    }
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

  @override
  void dispose() {
    // Restore previous filters if using ephemeral filters
    if (widget.ephemeralFilters) {
      final provider = context.read<TransactionProvider>();
      provider.clearAllFilters();
      
      if (_previousType != null) {
        provider.setTypeFilter(_previousType!);
      }
      if (_previousRange != null) {
        provider.setRangeFilter(_previousRange);
      }
      if (_previousCategory != null) {
        provider.setCategoryFilter(_previousCategory);
      }
      if (_previousQuery?.isNotEmpty == true) {
        provider.setQuery(_previousQuery!);
      }
    }
    
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    _searchController.clear();
    final provider = context.read<TransactionProvider>();
    provider.clearAllFilters();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keep alive
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isWeb = screenWidth > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        elevation: 0,
        actions: [
          Consumer<TransactionProvider>(
            builder: (_, provider, __) {
              final hasActiveFilters = provider.hasActiveFilters;
              return Row(children: [
                if (hasActiveFilters)
                  IconButton(
                    icon: const Icon(Icons.clear_all),
                    onPressed: _clearAllFilters,
                    tooltip: 'Clear all filters',
                  ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_alt),
                      onPressed: () => _showFilterBottomSheet(context, isWeb),
                      tooltip: 'Filter transactions',
                    ),
                    if (hasActiveFilters)
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
              ]);
            },
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              label: 'Search',
              hint: 'Search transactions...',
              controller: _searchController,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              showClearButton: true,
              onChanged: (value) {
                context.read<TransactionProvider>().setQuery(value);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Transactions List
          Expanded(
            child: Consumer<TransactionProvider>(
              builder: (context, transactionProvider, child) {
                final transactions = transactionProvider.filtered;
                final hasActiveFilters = transactionProvider.hasActiveFilters;

                // Initial loading state
                if (transactions.isEmpty &&
                    transactionProvider.hasMore &&
                    transactionProvider.all.isEmpty &&
                    !hasActiveFilters) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (transactions.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.receipt_long,
                    title: hasActiveFilters
                        ? 'No transactions match your filters'
                        : 'No transactions found',
                    subtitle: hasActiveFilters
                        ? 'Try adjusting your filters'
                        : 'Start by adding your first transaction',
                    action: hasActiveFilters
                        ? AppButton(
                            text: 'Clear Filters',
                            type: ButtonType.outlined,
                            onPressed: () {
                              context.read<TransactionProvider>().clearAllFilters();
                            },
                          )
                        : null,
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
                  itemCount: transactions.length + (transactionProvider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= transactions.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    
                    final transaction = transactions[index];
                    return Selector<CategoryProvider, CategoryModel>(
                      selector: (_, provider) => provider.getCategoryByName(
                        transaction.category,
                        isIncome: transaction.type == TransactionType.income,
                      ),
                      builder: (_, category, __) => TransactionItem(
                        transaction: transaction,
                        category: category,
                        onTap: () {
                          NavigationService.goToEditTransaction(context, transaction);
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

  void _showFilterBottomSheet(BuildContext context, bool isWeb) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _FilterBottomSheet(),
    );
  }
}

// Simplified Filter Bottom Sheet Component  
class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Filter Transactions',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Transaction Type Filter
                _TypeFilterSection(provider: provider),
                const SizedBox(height: 24),

                // Category Filter (only when specific type selected)
                if (provider.filterType != TransactionType.all)
                  _CategoryFilterSection(provider: provider),

                // Date Range Filter
                _DateRangeSection(provider: provider),
                const SizedBox(height: 32),

                // Close Button
                AppButton(
                  text: 'Close',
                  type: ButtonType.primary,
                  onPressed: () => NavigationService.goBack(context),
                  width: double.infinity,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Type Filter Section Component
class _TypeFilterSection extends StatelessWidget {
  const _TypeFilterSection({required this.provider});
  
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transaction Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: AppFilterChip(
                label: 'All',
                isSelected: provider.filterType == TransactionType.all,
                onTap: () => provider.setTypeFilter(TransactionType.all),
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppFilterChip(
                label: 'Income',
                isSelected: provider.filterType == TransactionType.income,
                onTap: () => provider.setTypeFilter(TransactionType.income),
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppFilterChip(
                label: 'Expense',
                isSelected: provider.filterType == TransactionType.expense,
                onTap: () => provider.setTypeFilter(TransactionType.expense),
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Category Filter Section Component
class _CategoryFilterSection extends StatelessWidget {
  const _CategoryFilterSection({required this.provider});
  
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Consumer<CategoryProvider>(
          builder: (context, catProvider, _) {
            final isIncome = provider.filterType == TransactionType.income;
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
                  value: provider.filterCategory,
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
                  onChanged: (val) => provider.setCategoryFilter(val),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// Date Range Section Component
class _DateRangeSection extends StatelessWidget {
  const _DateRangeSection({required this.provider});
  
  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        
        if (provider.filterRange != null) ...[
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
                const Icon(Icons.date_range, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${DateFormat('MMM dd, yyyy').format(provider.filterRange!.start)} - ${DateFormat('MMM dd, yyyy').format(provider.filterRange!.end)}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF4CAF50), size: 20),
                  onPressed: () => provider.setRangeFilter(null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        AppButton(
          text: provider.filterRange == null
              ? 'Select Date Range'
              : 'Change Date Range',
          icon: Icons.date_range,
          type: ButtonType.outlined,
          onPressed: () => _selectDateRange(context, provider),
          width: double.infinity,
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context, TransactionProvider provider) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: provider.filterRange,
    );
    
    if (picked != null) {
      provider.setRangeFilter(picked);
    }
  }
}
