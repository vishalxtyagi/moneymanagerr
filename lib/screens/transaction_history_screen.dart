import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/models/category_model.dart';
import 'package:moneymanager/core/providers/auth_provider.dart';
import 'package:moneymanager/core/providers/category_provider.dart';
import 'package:moneymanager/core/providers/transaction_provider.dart';
import 'package:moneymanager/screens/add_transaction_screen.dart';
import 'package:moneymanager/widgets/items/transaction_item.dart';
import 'package:provider/provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  /// Optional initial filters when navigating from summary or charts
  final TransactionType? initialType;
  final String? initialCategory;
  final DateTimeRange? initialRange;
  final String? initialQuery;
  final String? focusTransactionId;
  final bool ephemeralFilters; // if true, restore previous filters on pop
  const TransactionHistoryScreen({super.key, this.initialType, this.initialCategory, this.initialRange, this.initialQuery, this.focusTransactionId, this.ephemeralFilters = false});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  TransactionType _filterType = TransactionType.all;
  DateTimeRange? _dateRange;
  String? _category; // local mirror of provider category filter
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _didScrollToFocus = false;
  // Snapshot for ephemeral restore
  TransactionType? _prevType;
  DateTimeRange? _prevRange;
  String? _prevCategory;
  String? _prevQuery;

  void _ensureCategoryValid() {
    if (_category == null) return;
    final catProvider = context.read<CategoryProvider>();
    bool valid;
    switch (_filterType) {
      case TransactionType.income:
        valid = catProvider.incomeCategories.any((c) => c.name == _category);
        break;
      case TransactionType.expense:
        valid = catProvider.expenseCategories.any((c) => c.name == _category);
        break;
      case TransactionType.all:
        valid = catProvider.incomeCategories.any((c) => c.name == _category) ||
            catProvider.expenseCategories.any((c) => c.name == _category);
        break;
    }
    if (!valid) {
      setState(() => _category = null);
      context.read<TransactionProvider>().setCategoryFilter(null);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    final hasInitial = widget.initialType != null ||
        widget.initialRange != null ||
        widget.initialCategory != null ||
        (widget.initialQuery?.isNotEmpty ?? false);

    if (widget.ephemeralFilters && hasInitial) {
      // snapshot
      _prevType = transactionProvider.filterType;
      _prevRange = transactionProvider.filterRange;
      _prevCategory = transactionProvider.filterCategory;
      _prevQuery = transactionProvider.searchQuery;
      // clear existing filters completely
      transactionProvider.clearAllFilters();
      transactionProvider.setCategoryFilter(null); // ensure category cleared
    }

    // Apply initial filters (only the ones provided) without keeping stale ones
    if (widget.initialType != null) {
      transactionProvider.setTypeFilter(widget.initialType!);
    }
    if (widget.initialRange != null) {
      transactionProvider.setRangeFilter(widget.initialRange);
    }
    if (widget.initialCategory != null) {
      transactionProvider.setCategoryFilter(widget.initialCategory);
    }
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      transactionProvider.setQuery(widget.initialQuery!);
    }

    // Sync local state with provider (after applying overrides)
    _filterType = transactionProvider.filterType;
    _dateRange = transactionProvider.filterRange;
    _category = transactionProvider.filterCategory;
    _searchController.text = transactionProvider.searchQuery;

    // Remove duplicate fetch (auth-driven fetch already starts in provider)
    // Kept scroll listener for pagination
    _scrollController.addListener(() async {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final offset = _scrollController.offset;
      if (max - offset < 400) {
        final uid = context.read<AuthProvider>().user?.uid;
        final provider = context.read<TransactionProvider>();
        if (uid != null && provider.hasMore) {
          await provider.loadMore(uid);
        }
      }
    });
  }

  @override
  void dispose() {
    // Restore previous filters if ephemeral
    if (widget.ephemeralFilters && _prevType != null) {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      provider.clearAllFilters();
      provider.setTypeFilter(_prevType!);
      provider.setRangeFilter(_prevRange);
      provider.setCategoryFilter(_prevCategory);
      if ((_prevQuery ?? '').isNotEmpty) provider.setQuery(_prevQuery!);
    }
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange(BuildContext context,
      [StateSetter? modalSetState]) async {
    // Capture provider before awaiting to avoid using context across async gaps
    final txProvider = context.read<TransactionProvider>();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateRange) {
      if (!mounted) return;
      setState(() {
        _dateRange = picked;
      });
      // Update modal state if called from modal
      modalSetState?.call(() {
        _dateRange = picked;
      });
      txProvider.setRangeFilter(picked);
    }
  }

  void _clearDateFilter([StateSetter? modalSetState]) {
    setState(() {
      _dateRange = null;
    });
    // Update modal state if called from modal
    modalSetState?.call(() {
      _dateRange = null;
    });
    Provider.of<TransactionProvider>(context, listen: false)
        .setRangeFilter(null);
  }

  void _clearAllFilters() {
    setState(() {
      _filterType = TransactionType.all;
      _dateRange = null;
      _searchController.clear();
  _category = null;
    });
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);
    transactionProvider.clearAllFilters();
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
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppStyles.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search transactions...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                          context.read<TransactionProvider>().setQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppStyles.borderRadius),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
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
                // Attempt auto-scroll to focused transaction once data present
                if (!_didScrollToFocus && widget.focusTransactionId != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final idx = transactions.indexWhere((t) => t.id == widget.focusTransactionId);
                    if (idx != -1) {
                      _didScrollToFocus = true;
                      _scrollController.animateTo(
                        (idx * 80).toDouble().clamp(0, _scrollController.position.hasContentDimensions ? _scrollController.position.maxScrollExtent : 50000),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                }
                final hasActiveFilters = transactionProvider.hasActiveFilters;

                // Initial loading state: no data yet but more expected
                if (transactions.isEmpty &&
                    transactionProvider.hasMore &&
                    transactionProvider.all.isEmpty &&
                    !hasActiveFilters) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (transactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          hasActiveFilters
                              ? 'No transactions match your filters'
                              : 'No transactions found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          hasActiveFilters
                              ? 'Try adjusting your filters'
                              : 'Start by adding your first transaction',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (hasActiveFilters) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _clearAllFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                            child: const Text(
                              'Clear Filters',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (_) => false,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding:
                        EdgeInsets.symmetric(horizontal: isWeb ? 24 : 16),
                    itemCount: transactions.length + (transactionProvider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final transaction = transactions[index];
                      final isFocused = transaction.id == widget.focusTransactionId;
                      return Selector<CategoryProvider, CategoryModel>(
                        selector: (_, provider) =>
                            provider.getCategoryByName(transaction.category,
                                isIncome: transaction.type ==
                                    TransactionType.income),
                        builder: (_, category, __) => Container(
                          decoration: isFocused
                              ? BoxDecoration(
                                  border: Border.all(color: Colors.amber, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: TransactionItem(
                            transaction: transaction,
                            category: category,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddTransactionScreen(
                                      transaction: transaction),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
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
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
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
                        child: _buildFilterChip(
                          'All',
                          _filterType == TransactionType.all,
                          () {
                            setState(() => _filterType = TransactionType.all);
                            setModalState(
                                () => _filterType = TransactionType.all);
                            Provider.of<TransactionProvider>(context,
                                    listen: false)
                                .setTypeFilter(TransactionType.all);
                            _ensureCategoryValid();
                            if (_category != null) {
                              setState(() => _category = null);
                              setModalState(() => _category = null);
                              Provider.of<TransactionProvider>(context, listen: false)
                                  .setCategoryFilter(null);
                            }
                          },
                          AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterChip(
                          'Income',
                          _filterType == TransactionType.income,
                          () {
                            setState(
                                () => _filterType = TransactionType.income);
                            setModalState(
                                () => _filterType = TransactionType.income);
                            Provider.of<TransactionProvider>(context,
                                    listen: false)
                                .setTypeFilter(TransactionType.income);
                            _ensureCategoryValid();
                          },
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildFilterChip(
                          'Expense',
                          _filterType == TransactionType.expense,
                          () {
                            setState(
                                () => _filterType = TransactionType.expense);
                            setModalState(
                                () => _filterType = TransactionType.expense);
                            Provider.of<TransactionProvider>(context,
                                    listen: false)
                                .setTypeFilter(TransactionType.expense);
                            _ensureCategoryValid();
                          },
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_filterType != TransactionType.all) ...[
                    // Category Filter (only when specific type selected)
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
                        final isIncome = _filterType == TransactionType.income;
                        final categories = isIncome
                            ? catProvider.incomeCategories
                            : catProvider.expenseCategories;
                        final List<DropdownMenuItem<String?>> items = [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map((c) => DropdownMenuItem<String?>(
                                value: c.name,
                                child: Text(c.name),
                              ))
                        ];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _category,
                              isExpanded: true,
                              items: items,
                              onChanged: (val) {
                                setState(() => _category = val);
                                setModalState(() => _category = val);
                                Provider.of<TransactionProvider>(context, listen: false)
                                    .setCategoryFilter(val);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Date Range Filter
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_dateRange != null) ...[
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
                              '${DateFormat('MMM dd, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(_dateRange!.end)}',
                              style: const TextStyle(
                                color: Color(0xFF4CAF50),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear,
                                color: Color(0xFF4CAF50), size: 20),
                            onPressed: () {
                              _clearDateFilter(setModalState);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _selectDateRange(context, setModalState),
                          icon: const Icon(Icons.date_range, size: 20),
                          label: Text(_dateRange == null
                              ? 'Select Date Range'
                              : 'Change Date Range'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[100],
                            foregroundColor: Colors.grey[700],
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF44336),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppStyles.borderRadius),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, bool isSelected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
