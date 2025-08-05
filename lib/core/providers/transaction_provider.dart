import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  List<TransactionModel> get all => _all;

  List<TransactionModel> get filtered => _filtered;

  TransactionType get filterType => _typeFilter;

  DateTimeRange? get filterRange => _rangeFilter;

  String get searchQuery => _query;

  bool get hasActiveFilters => _typeFilter != TransactionType.all || _rangeFilter != null;

  Future<void> fetch(String userId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    _all
      ..clear()
      ..addAll(snapshot.docs.map(TransactionModel.fromFirestore))
      ..sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.createdAt.compareTo(a.createdAt);
      });

    _applyFilters();
    notifyListeners();
  }

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

      await _firestore.collection('transactions').doc(id).set({
        'id': id,
        'userId': userId,
        'title': title,
        'amount': amount,
        'date': Timestamp.fromDate(date),
        'category': category,
        'type': type.name,
        'note': note,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await fetch(userId);
    } catch (e) {
      debugPrint('Add Error: $e');
      rethrow;
    }
  }

  Future<void> update(TransactionModel txn) async {
    try {
      await _firestore.collection('transactions').doc(txn.id).update({
        ...txn.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await fetch(txn.userId);
    } catch (e) {
      debugPrint('Update Error: $e');
      rethrow;
    }
  }

  Future<void> remove(String id, String userId) async {
    try {
      await _firestore.collection('transactions').doc(id).delete();
      await fetch(userId);
    } catch (e) {
      debugPrint('Delete Error: $e');
      rethrow;
    }
  }

  void setTypeFilter(TransactionType type) {
    if (_typeFilter == type) return;
    _typeFilter = type;
    _applyFilters();
    notifyListeners();
  }

  void setRangeFilter(DateTimeRange? range) {
    if (_rangeFilter == range) return;
    _rangeFilter = range;
    _applyFilters();
    notifyListeners();
  }

  void setQuery(String query) {
    final q = query.toLowerCase();
    if (_query == q) return;
    _query = q;
    _applyFilters();
    notifyListeners();
  }

  void clearAllFilters() {
    _typeFilter = TransactionType.all;
    _rangeFilter = null;
    _query = '';
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filtered
      ..clear()
      ..addAll(_all.where((txn) {
        final matchesType =
            _typeFilter == TransactionType.all || txn.type == _typeFilter;
        final matchesDate = _rangeFilter == null ||
            (txn.date.isAfter(
                    _rangeFilter!.start.subtract(const Duration(days: 1))) &&
                txn.date
                    .isBefore(_rangeFilter!.end.add(const Duration(days: 1))));
        final matchesQuery = _query.isEmpty ||
            txn.title.toLowerCase().contains(_query) ||
            txn.category.toLowerCase().contains(_query) ||
            (txn.note?.toLowerCase().contains(_query) ?? false);
        return matchesType && matchesDate && matchesQuery;
      }));
  }

  List<TransactionModel> _filterByRange(DateTimeRange? range) {
    if (range == null) return _all;
    final start = range.start.subtract(const Duration(days: 1));
    final end = range.end.add(const Duration(days: 1));
    return _all
        .where((txn) => txn.date.isAfter(start) && txn.date.isBefore(end))
        .toList();
  }

  double getTotalIncome({DateTimeRange? range}) => _filterByRange(range)
      .where((txn) => txn.type == TransactionType.income)
      .fold(0.0, (total, txn) => total + txn.amount);

  double getTotalExpense({DateTimeRange? range}) => _filterByRange(range)
      .where((txn) => txn.type == TransactionType.expense)
      .fold(0.0, (total, txn) => total + txn.amount);

  double getBalance({DateTimeRange? range}) =>
      getTotalIncome(range: range) - getTotalExpense(range: range);

  Map<String, double> getExpensesByCategory({DateTimeRange? range}) {
    final data = <String, double>{};
    for (final txn in _filterByRange(range)
        .where((txn) => txn.type == TransactionType.expense)) {
      data[txn.category] = (data[txn.category] ?? 0) + txn.amount;
    }
    return Map.fromEntries(
        data.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  List<MapEntry<String, double>> getTopCategories({int count = 5}) =>
      getExpensesByCategory().entries.take(count).toList();

  bool isNearBreakEven({double limit = 100.0}) {
    final bal = getBalance();
    return bal > 0 && bal <= limit;
  }

  List<TransactionModel> getByDateRange(DateTime start, DateTime end) {
    final adjustedStart = start.subtract(const Duration(days: 1));
    final adjustedEnd = end.add(const Duration(days: 1));
    return _all
        .where((txn) =>
            txn.date.isAfter(adjustedStart) && txn.date.isBefore(adjustedEnd))
        .toList();
  }
}
