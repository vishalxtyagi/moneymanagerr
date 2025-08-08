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
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with AutomaticKeepAliveClientMixin {
  TransactionType _filterType = TransactionType.all;
  DateTimeRange? _dateRange;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final transactionProvider =
        Provider.of<TransactionProvider>(context, listen: false);

    // Sync local state with provider state
    _filterType = transactionProvider.filterType;
    _dateRange = transactionProvider.filterRange;
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
              final hasActiveFilters =
                  provider.filterType != TransactionType.all ||
                      provider.filterRange != null ||
                      provider.searchQuery.isNotEmpty;
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
                final hasActiveFilters =
                    transactionProvider.filterType != TransactionType.all ||
                        transactionProvider.filterRange != null ||
                        transactionProvider.searchQuery.isNotEmpty;

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
                      return Selector<CategoryProvider, CategoryModel>(
                        selector: (_, provider) =>
                            provider.getCategoryByName(transaction.category,
                                isIncome: transaction.type ==
                                    TransactionType.income),
                        builder: (_, category, __) => TransactionItem(
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
                          },
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

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
