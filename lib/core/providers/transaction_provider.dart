import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/models/transaction_model.dart';
import 'dart:collection';
import 'dart:async';

class TransactionProvider with ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;

  // Typed collection reference with converter
  CollectionReference<TransactionModel> get _txCol => _firestore
      .collection('transactions')
      .withConverter<TransactionModel>(
        fromFirestore: (snap, _) => TransactionModel.fromFirestore(snap),
        toFirestore: (txn, _) => txn.toMap(),
      );

  final List<TransactionModel> _all = [];
  final List<TransactionModel> _filtered = [];

  // Cached aggregates and counters
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _todayCount = 0;
  int _monthCount = 0;

  // Live subscriptions (typed)
  StreamSubscription<QuerySnapshot<TransactionModel>>? _dashboardSub;

  TransactionType _typeFilter = TransactionType.all;
  DateTimeRange? _rangeFilter;
  String _query = '';
  String? _categoryFilter;
  Timer? _searchDebounce;

  User? _currentUser;

  // Cache for search blobs to avoid repeated toLowerCase joins
  final Map<String, String> _searchBlobCache = {};

  // Getters
  UnmodifiableListView<TransactionModel> get all =>
      UnmodifiableListView(_all);
  UnmodifiableListView<TransactionModel> get filtered =>
      UnmodifiableListView(_filtered);
  TransactionType get filterType => _typeFilter;
  DateTimeRange? get filterRange => _rangeFilter;
  String get searchQuery => _query;
  String? get filterCategory => _categoryFilter;
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  int get todayCount => _todayCount;
  int get monthCount => _monthCount;
  bool get hasActiveFilters =>
      _typeFilter != TransactionType.all ||
      _rangeFilter != null ||
  _categoryFilter != null;

  /// Helpers for date checks
  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isThisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  /// Update auth state
  void updateAuth(User? user) {
    if (_currentUser?.uid != user?.uid) {
      _currentUser = user;
      _cancelStreams();
      _clearData();
      if (user != null) {
        // Start a lightweight live feed for dashboard (latest 50)
        _subscribeDashboardFeed(user.uid, limit: 50);
        // For history screen initial load; still allow fetch() legacy for now
        fetch(user.uid);
      } else {
        notifyListeners();
      }
    }
  }

  void _cancelStreams() {
    _dashboardSub?.cancel();
    _dashboardSub = null;
  }

  void disposeProvider() {
    _cancelStreams();
    _searchDebounce?.cancel();
  }

  @override
  void dispose() {
    _cancelStreams();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _recomputeAggregatesAndCounters() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _todayCount = 0;
    _monthCount = 0;
    final now = DateTime.now();

    _searchBlobCache.clear();

    for (final txn in _all) {
      if (txn.type == TransactionType.income) {
        _totalIncome += txn.amount;
      } else if (txn.type == TransactionType.expense) {
        _totalExpense += txn.amount;
      }

      if (txn.date.year == now.year &&
          txn.date.month == now.month &&
          txn.date.day == now.day) {
        _todayCount++;
      }
      if (txn.date.year == now.year && txn.date.month == now.month) {
        _monthCount++;
      }

      _searchBlobCache[txn.id] =
          '${txn.title} ${txn.category} ${txn.note ?? ''}'.toLowerCase();
    }
  }

  void _onTxnInserted(TransactionModel optimistic) {
    _all.insert(0, optimistic);
    if (optimistic.type == TransactionType.income) {
      _totalIncome += optimistic.amount;
    } else if (optimistic.type == TransactionType.expense) {
      _totalExpense += optimistic.amount;
    }
    final now = DateTime.now();
    if (optimistic.date.year == now.year &&
        optimistic.date.month == now.month &&
        optimistic.date.day == now.day) {
      _todayCount++;
    }
    if (optimistic.date.year == now.year &&
        optimistic.date.month == now.month) {
      _monthCount++;
    }
    _searchBlobCache[optimistic.id] =
        '${optimistic.title} ${optimistic.category} ${optimistic.note ?? ''}'.toLowerCase();
  }

  void _onTxnRemoved(TransactionModel removed) {
    if (removed.type == TransactionType.income) {
      _totalIncome -= removed.amount;
    } else if (removed.type == TransactionType.expense) {
      _totalExpense -= removed.amount;
    }
    final now = DateTime.now();
    if (removed.date.year == now.year &&
        removed.date.month == now.month &&
        removed.date.day == now.day) {
      _todayCount = (_todayCount - 1).clamp(0, 1 << 31);
    }
    if (removed.date.year == now.year && removed.date.month == now.month) {
      _monthCount = (_monthCount - 1).clamp(0, 1 << 31);
    }
    _searchBlobCache.remove(removed.id);
  }

  void _sortAll() {
    _all.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  /// Live feed for latest N items (merge without dropping older paginated items)
  void _subscribeDashboardFeed(String userId, {int limit = 50}) {
    _dashboardSub = _txCol
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        final model = change.doc.data();
        if (model == null) continue;
        final idx = _all.indexWhere((t) => t.id == model.id);
        switch (change.type) {
          case DocumentChangeType.added:
          case DocumentChangeType.modified:
            if (idx == -1) {
              _all.insert(0, model);
            } else {
              _all[idx] = model;
            }
            _searchBlobCache[model.id] =
                '${model.title} ${model.category} ${model.note ?? ''}'.toLowerCase();
            break;
          case DocumentChangeType.removed:
            if (idx != -1) {
              final removed = _all.removeAt(idx);
              _onTxnRemoved(removed);
            }
            break;
        }
      }
      _sortAll();
      _recomputeAggregatesAndCounters();
      _applyFilters();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Dashboard stream error: $e');
    });
  }

  /// Fetch transactions for user (full list; to be used by history with pagination later)
  Future<void> fetch(String userId) async {
    try {
      final snapshot = await _txCol
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      _all
        ..clear()
        ..addAll(snapshot.docs.map((d) => d.data()));

      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == 200;

      _recomputeAggregatesAndCounters();
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch Error: $e');
      rethrow;
    }
  }

  /// Pagination support for history screen
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  bool get hasMore => _hasMore;

  Future<void> loadMore(String userId, {int pageSize = 50}) async {
    if (!_hasMore) return;
    try {
      Query<TransactionModel> query = _txCol
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(pageSize);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        _all.addAll(snapshot.docs.map((d) => d.data()));
        _applyFilters();
        notifyListeners();
      }
      if (snapshot.docs.length < pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Load more error: $e');
    }
  }

  /// Add new transaction (optimistic append)
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

      final optimistic = TransactionModel(
        id: id,
        userId: userId,
        title: title,
        amount: amount,
        date: date,
        category: category,
        type: type,
        note: note,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _onTxnInserted(optimistic);
      _applyFilters();
      notifyListeners();

      await _firestore.collection('transactions').doc(id).set({
        // Remove 'id' field if you prefer doc.id only. Keeping for compatibility
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
    } catch (e) {
      if (_currentUser != null) await fetch(_currentUser!.uid);
      debugPrint('Add Error: $e');
      rethrow;
    }
  }

  /// Update transaction with optimized local update; createdAt immutable
  Future<void> update(TransactionModel txn) async {
    try {
      _updateTransactionInMemory(txn);

      final map = txn.toMap();
      map.remove('createdAt');

      await _firestore.collection('transactions').doc(txn.id).update({
        ...map,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (_currentUser != null) await fetch(_currentUser!.uid);
      debugPrint('Update Error: $e');
      rethrow;
    }
  }

  /// Remove transaction with optimized local removal
  Future<void> remove(String id, String userId) async {
    try {
      final idx = _all.indexWhere((t) => t.id == id);
      TransactionModel? removed;
      if (idx != -1) {
        removed = _all.removeAt(idx);
        _onTxnRemoved(removed);
      }
      _applyFilters();
      notifyListeners();

      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      if (_currentUser != null) await fetch(_currentUser!.uid);
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

  /// Set search query (debounced)
  void setQuery(String query) {
    final q = query.toLowerCase().trim();
    if (_query == q) return;
    _query = q;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _applyFilters();
      notifyListeners();
    });
  }

  /// Clear all filters
  void clearAllFilters() {
    if (!hasActiveFilters) return;
    _typeFilter = TransactionType.all;
    _rangeFilter = null;
    _query = '';
  _categoryFilter = null;
    _applyFilters();
    notifyListeners();
  }

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  void _applyFilters() {
    _filtered.clear();
    for (final txn in _all) {
      if (_matchesAllFilters(txn)) {
        _filtered.add(txn);
      }
    }
  }

  bool _matchesAllFilters(TransactionModel txn) {
    if (_typeFilter != TransactionType.all && txn.type != _typeFilter) {
      return false;
    }
    if (_rangeFilter != null) {
      final start = _rangeFilter!.start;
      final end = _endOfDay(_rangeFilter!.end);
      if (txn.date.isBefore(start) || txn.date.isAfter(end)) {
        return false;
      }
    }
    if (_query.isNotEmpty) {
      final blob = _searchBlobCache[txn.id] ??= (
          '${txn.title} ${txn.category} ${txn.note ?? ''}'.toLowerCase());
      if (!blob.contains(_query)) return false;
    }
    if (_categoryFilter != null && txn.category != _categoryFilter) {
      return false;
    }
    return true;
  }

  List<TransactionModel> _filterByRange(DateTimeRange? range) {
    if (range == null) return _all;
    final end = _endOfDay(range.end);
    return _all
        .where((txn) => !txn.date.isBefore(range.start) && !txn.date.isAfter(end))
        .toList();
  }

  double getTotalIncome({DateTimeRange? range}) {
    if (range == null) return _totalIncome;
    return _filterByRange(range)
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (total, txn) => total + txn.amount);
  }

  double getTotalExpense({DateTimeRange? range}) {
    if (range == null) return _totalExpense;
    return _filterByRange(range)
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (total, txn) => total + txn.amount);
  }

  double getBalance({DateTimeRange? range}) {
    return getTotalIncome(range: range) - getTotalExpense(range: range);
  }

  Map<String, double> getExpensesByCategory({DateTimeRange? range}) {
    final expenses = <String, double>{};
    for (final txn in _filterByRange(range)) {
      if (txn.type == TransactionType.expense) {
        expenses[txn.category] = (expenses[txn.category] ?? 0) + txn.amount;
      }
    }
    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sortedEntries);
  }

  List<MapEntry<String, double>> getTopCategories({int count = 5}) {
    return getExpensesByCategory().entries.take(count).toList();
  }

  bool isNearBreakEven({double threshold = 100.0}) {
    final balance = getBalance();
    return balance > 0 && balance <= threshold;
  }

  List<TransactionModel> getByDateRange(DateTime start, DateTime end) {
    final eod = _endOfDay(end);
    return _all
        .where((txn) => !txn.date.isBefore(start) && !txn.date.isAfter(eod))
        .toList();
  }

  /// Clear all data and filters
  void _clearData() {
    _all.clear();
    _filtered.clear();
    _typeFilter = TransactionType.all;
    _rangeFilter = null;
    _query = '';
  _categoryFilter = null;
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _todayCount = 0;
    _monthCount = 0;
    _lastDoc = null;
    _hasMore = true;
  }

  /// Optimized local update + adjust aggregates and counters
  void _updateTransactionInMemory(TransactionModel updatedTxn) {
    final index = _all.indexWhere((t) => t.id == updatedTxn.id);
    if (index == -1) return;

    final old = _all[index];

    // Adjust aggregates
    if (old.type == TransactionType.income) {
      _totalIncome -= old.amount;
    } else if (old.type == TransactionType.expense) {
      _totalExpense -= old.amount;
    }
    if (updatedTxn.type == TransactionType.income) {
      _totalIncome += updatedTxn.amount;
    } else if (updatedTxn.type == TransactionType.expense) {
      _totalExpense += updatedTxn.amount;
    }

    // Adjust counters
    if (_isToday(old.date)) _todayCount = (_todayCount - 1).clamp(0, 1 << 31);
    if (_isThisMonth(old.date)) _monthCount = (_monthCount - 1).clamp(0, 1 << 31);
    if (_isToday(updatedTxn.date)) _todayCount++;
    if (_isThisMonth(updatedTxn.date)) _monthCount++;

    _all[index] = updatedTxn;
    _applyFilters();
    notifyListeners();
  }

  /// Set category filter (null clears)
  void setCategoryFilter(String? category) {
    if (_categoryFilter == category) return;
    _categoryFilter = category?.isEmpty == true ? null : category;
    _applyFilters();
    notifyListeners();
  }
}
