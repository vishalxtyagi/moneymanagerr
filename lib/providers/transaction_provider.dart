import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:moneymanager/shared/models/transaction.dart';
import 'package:uuid/uuid.dart';

class TransactionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String _filterType = 'all'; // 'all', 'income', 'expense'
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  List<TransactionModel> get recentTranactions => _transactions.take(5).toList();
  List<TransactionModel> get transactions => _filteredTransactions;
  String get filterType => _filterType;
  DateTimeRange? get dateRange => _dateRange;
  String get searchQuery => _searchQuery;

  Future<void> fetchTransactions(String userId) async {
      QuerySnapshot snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .get();

      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      _transactions.sort((a, b) {
        int dateComparison = b.date.compareTo(a.date);
        if (dateComparison != 0) return dateComparison;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      _applyFilters();
      notifyListeners();
  }

  Future<void> addTransaction({
    required String userId,
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required String type,
    String? note,
  }) async {
    try {
      const uuid = Uuid();
      String id = uuid.v4();

      // Ensure date has no time component
      DateTime dateOnly = DateTime(date.year, date.month, date.day);

      await _firestore.collection('transactions').doc(id).set({
        'id': id,
        'userId': userId,
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(dateOnly),
        'category': category,
        'type': type,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(), // Server-generated timestamp
      });

      await fetchTransactions(userId);
    } catch (e) {
      debugPrint('Error adding transaction: $e');
      rethrow;
    }
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    try {
      await _firestore
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());

      await fetchTransactions(transaction.userId);
    } catch (e) {
      debugPrint('Error updating transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String id, String userId) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
      await fetchTransactions(userId);
    } catch (e) {
      debugPrint('Error deleting transaction: $e');
      rethrow;
    }
  }

  void setFilterType(String type) {
    _filterType = type;
    _applyFilters();
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  void clearFilters() {
    _filterType = 'all';
    _dateRange = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredTransactions = _transactions.where((transaction) {
      // Apply type filter
      bool typeMatch = _filterType == 'all' || transaction.type == _filterType;

      // Apply date range filter if set
      bool dateMatch = _dateRange == null ||
          (transaction.date.isAfter(_dateRange!.start) &&
              transaction.date.isBefore(_dateRange!.end));

      // Apply search filter
      bool searchMatch = _searchQuery.isEmpty ||
          transaction.title.toLowerCase().contains(_searchQuery) ||
          transaction.category.toLowerCase().contains(_searchQuery) ||
          (transaction.note?.toLowerCase().contains(_searchQuery) ?? false);

      return typeMatch && dateMatch && searchMatch;
    }).toList();

    
  }

  double getTotalIncome({DateTimeRange? dateRange}) {
    var transactions = dateRange != null ? _getTransactionsInRange(dateRange) : _transactions;
    return transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getTotalExpense({DateTimeRange? dateRange}) {
    var transactions = dateRange != null ? _getTransactionsInRange(dateRange) : _transactions;
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double getBalance({DateTimeRange? dateRange}) {
    return getTotalIncome(dateRange: dateRange) - getTotalExpense(dateRange: dateRange);
  }

  Map<String, double> getCategoryWiseExpenses({DateTimeRange? dateRange}) {
    final transactions = (dateRange != null ? _getTransactionsInRange(dateRange) : _transactions)
        .where((t) => t.type == 'expense');

    final categoryMap = <String, double>{};
    for (final t in transactions) {
      categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
    }

    return Map.fromEntries(
      categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  // Helper method to get transactions within a date range
  List<TransactionModel> _getTransactionsInRange(DateTimeRange dateRange) {
    return _transactions.where((transaction) =>
        transaction.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
        transaction.date.isBefore(dateRange.end.add(const Duration(days: 1)))).toList();
  }

  // Get transactions for a specific date range
  List<TransactionModel> getTransactionsForDateRange(DateTime start, DateTime end) {
    return _transactions.where((transaction) =>
        transaction.date.isAfter(start.subtract(const Duration(days: 1))) &&
        transaction.date.isBefore(end.add(const Duration(days: 1)))).toList();
  }

  // Get top spending categories
  List<MapEntry<String, double>> getTopSpendingCategories({int limit = 5}) {
    final categoryExpenses = getCategoryWiseExpenses();
    final sortedCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedCategories.take(limit).toList();
  }

  // Calculate consumption rate (expense as percentage of income)
  double getConsumptionRate({DateTimeRange? dateRange}) {
    final income = getTotalIncome(dateRange: dateRange);
    final expense = getTotalExpense(dateRange: dateRange);
    if (income == 0) return 0.0;
    return (expense / income) * 100;
  }

  // Check if user is approaching break-even balance
  bool isApproachingBreakEven({double threshold = 100.0}) {
    final balance = getBalance();
    return balance > 0 && balance <= threshold;
  }
}