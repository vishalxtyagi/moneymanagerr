import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  final List<TransactionModel> _all = [];
  final List<TransactionModel> _filtered = [];

  TransactionType _typeFilter = TransactionType.all;
  DateTimeRange? _rangeFilter;
  String _query = '';

  User? _currentUser;

  // Getters
  List<TransactionModel> get all => _all;
  List<TransactionModel> get filtered => _filtered;
  TransactionType get filterType => _typeFilter;
  DateTimeRange? get filterRange => _rangeFilter;
  String get searchQuery => _query;
  bool get hasActiveFilters =>
      _typeFilter != TransactionType.all ||
      _rangeFilter != null ||
      _query.isNotEmpty;

  /// Update auth state (called by main provider)
  void updateAuth(User? user) {
    if (_currentUser?.uid != user?.uid) {
      _currentUser = user;
      _clearData();
      if (user != null) {
        fetch(user.uid);
      }
    }
  }

  /// Optimized method to update specific transaction in memory
  void _updateTransactionInMemory(TransactionModel updatedTxn) {
    final index = _all.indexWhere((txn) => txn.id == updatedTxn.id);
    if (index != -1) {
      _all[index] = updatedTxn;
      _applyFilters();
      notifyListeners();
    }
  }

  /// Optimized method to remove transaction from memory
  void _removeTransactionFromMemory(String id) {
    _all.removeWhere((txn) => txn.id == id);
    _applyFilters();
    notifyListeners();
  }

  /// Clear all data
  void _clearData() {
    _all.clear();
    _filtered.clear();
    _typeFilter = TransactionType.all;
    _rangeFilter = null;
    _query = '';
    notifyListeners();
  }

  /// Fetch transactions for user
  Future<void> fetch(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      _all
        ..clear()
        ..addAll(snapshot.docs.map(TransactionModel.fromFirestore));

      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch Error: $e');
      rethrow;
    }
  }

  /// Add new transaction
  Future<void> add({
    required String userId,
    required String title,
    required double amount,
    required DateTime date,
    required String category,
    required TransactionType type,
    String? note,
  }) async {
    try {
      final id = const Uuid().v4();
      final now = FieldValue.serverTimestamp();

      await _firestore.collection('transactions').doc(id).set({
        'id': id,
        'userId': userId,
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'category': category,
        'type': type.name,
        'note': note,
        'createdAt': now,
        'updatedAt': now,
      });

      await fetch(userId);
    } catch (e) {
      debugPrint('Add Error: $e');
      rethrow;
    }
  }

  /// Update transaction with optimized local update
  Future<void> update(TransactionModel txn) async {
    try {
      // Optimistic update
      _updateTransactionInMemory(txn);

      await _firestore.collection('transactions').doc(txn.id).update({
        ...txn.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Revert on error
      await fetch(txn.userId);
      debugPrint('Update Error: $e');
      rethrow;
    }
  }

  /// Remove transaction with optimized local removal
  Future<void> remove(String id, String userId) async {
    try {
      // Optimistic removal
      _removeTransactionFromMemory(id);

      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      // Revert on error
      await fetch(userId);
      debugPrint('Delete Error: $e');
      rethrow;
    }
  }

  /// Set type filter
  void setTypeFilter(TransactionType type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    _applyFilters();
    notifyListeners();
  }

  /// Set date range filter
  void setRangeFilter(DateTimeRange? range) {
    if (_rangeFilter == range) return;
    _rangeFilter = range;
    _applyFilters();
    notifyListeners();
  }

  /// Set search query
  void setQuery(String query) {
    final q = query.toLowerCase().trim();
    if (_query == q) return;
    _query = q;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all filters
  void clearAllFilters() {
    if (!hasActiveFilters) return;

    _typeFilter = TransactionType.all;
    _rangeFilter = null;
    _query = '';
    _applyFilters();
    notifyListeners();
  }

  /// Apply all filters to transactions
  void _applyFilters() {
    _filtered.clear();

    for (final txn in _all) {
      if (_matchesAllFilters(txn)) {
        _filtered.add(txn);
      }
    }
  }

  /// Check if transaction matches all active filters
  bool _matchesAllFilters(TransactionModel txn) {
    // Type filter
    if (_typeFilter != TransactionType.all && txn.type != _typeFilter) {
      return false;
    }

    // Date range filter
    if (_rangeFilter != null) {
      if (txn.date.isBefore(_rangeFilter!.start) ||
          txn.date.isAfter(_rangeFilter!.end.add(const Duration(days: 1)))) {
        return false;
      }
    }

    // Search query filter
    if (_query.isNotEmpty) {
      final searchIn =
          '${txn.title} ${txn.category} ${txn.note ?? ''}'.toLowerCase();
      if (!searchIn.contains(_query)) {
        return false;
      }
    }

    return true;
  }

  /// Filter transactions by date range
  List<TransactionModel> _filterByRange(DateTimeRange? range) {
    if (range == null) return _all;

    return _all
        .where((txn) =>
            !txn.date.isBefore(range.start) &&
            !txn.date.isAfter(range.end.add(const Duration(days: 1))))
        .toList();
  }

  /// Calculate total income for date range
  double getTotalIncome({DateTimeRange? range}) {
    return _filterByRange(range)
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (total, txn) => total + txn.amount);
  }

  /// Calculate total expense for date range
  double getTotalExpense({DateTimeRange? range}) {
    return _filterByRange(range)
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (total, txn) => total + txn.amount);
  }

  /// Calculate balance for date range
  double getBalance({DateTimeRange? range}) {
    return getTotalIncome(range: range) - getTotalExpense(range: range);
  }

  /// Get expenses grouped by category
  Map<String, double> getExpensesByCategory({DateTimeRange? range}) {
    final expenses = <String, double>{};

    for (final txn in _filterByRange(range)) {
      if (txn.type == TransactionType.expense) {
        expenses[txn.category] = (expenses[txn.category] ?? 0) + txn.amount;
      }
    }

    // Sort by value descending
    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Get top spending categories
  List<MapEntry<String, double>> getTopCategories({int count = 5}) {
    return getExpensesByCategory().entries.take(count).toList();
  }

  /// Check if balance is near break-even
  bool isNearBreakEven({double threshold = 100.0}) {
    final balance = getBalance();
    return balance > 0 && balance <= threshold;
  }

  /// Get transactions within date range
  List<TransactionModel> getByDateRange(DateTime start, DateTime end) {
    return _all
        .where((txn) =>
            !txn.date.isBefore(start) &&
            !txn.date.isAfter(end.add(const Duration(days: 1))))
        .toList();
  }
}
