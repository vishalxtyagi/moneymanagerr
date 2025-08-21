import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/utils/notifier_utils.dart';
import 'dart:collection';
import 'dart:async';

class TransactionProvider with ChangeNotifier, NotifierMixin {
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<TransactionModel> get _txCol =>
      _firestore.collection('transactions').withConverter<TransactionModel>(
            fromFirestore: (snap, _) => TransactionModel.fromFirestore(snap),
            toFirestore: (txn, _) => txn.toMap(),
          );

  final List<TransactionModel> _all = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  int _todayCount = 0;
  int _monthCount = 0;

  StreamSubscription<QuerySnapshot<TransactionModel>>? _dashboardSub;
  DocumentSnapshot? _lastDoc;
  bool _hasMore = true;
  User? _currentUser;

  UnmodifiableListView<TransactionModel> get all => UnmodifiableListView(_all);
  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  int get todayCount => _todayCount;
  int get monthCount => _monthCount;
  bool get hasMore => _hasMore;

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isThisMonth(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month;
  }

  void updateAuth(User? user) {
    if (_currentUser?.uid != user?.uid) {
      _currentUser = user;
      _cancelStreams();
      _clearData();
      if (user != null) {
        _subscribeDashboardFeed(user.uid, limit: 50);
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
  }

  @override
  void dispose() {
    _cancelStreams();
    super.dispose();
  }

  void _recomputeAggregatesAndCounters() {
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _todayCount = 0;
    _monthCount = 0;
    final now = DateTime.now();

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
  }

  void _sortAll() {
    _all.sort((a, b) {
      final byDate = b.date.compareTo(a.date);
      if (byDate != 0) return byDate;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

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
            break;
          case DocumentChangeType.removed:
            if (idx != -1) {
              final removed = _all.removeAt(idx);
              _onTxnRemoved(removed);
            }
            break;
        }
      }

      batchUpdate(() {
        _sortAll();
        _recomputeAggregatesAndCounters();
      });
    }, onError: (e) {
      debugPrint('Dashboard stream error: $e');
    });
  }

  Future<void> fetch(String userId) async {
    try {
      final snapshot = await _txCol
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .orderBy('createdAt', descending: true)
          .limit(200)
          .get();

      batchUpdate(() {
        _all
          ..clear()
          ..addAll(snapshot.docs.map((d) => d.data()));

        _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
        _hasMore = snapshot.docs.length == 200;

        _recomputeAggregatesAndCounters();
      });
    } catch (e) {
      debugPrint('Fetch Error: $e');
      rethrow;
    }
  }

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
        notifyListeners();
      }
      if (snapshot.docs.length < pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Load more error: $e');
    }
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
      notifyListeners();

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
    } catch (e) {
      if (_currentUser != null) await fetch(_currentUser!.uid);
      debugPrint('Add Error: $e');
      rethrow;
    }
  }

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

  Future<void> remove(String id, String userId) async {
    try {
      final idx = _all.indexWhere((t) => t.id == id);
      TransactionModel? removed;
      if (idx != -1) {
        removed = _all.removeAt(idx);
        _onTxnRemoved(removed);
      }
      notifyListeners();

      await _firestore.collection('transactions').doc(id).delete();
    } catch (e) {
      if (_currentUser != null) await fetch(_currentUser!.uid);
      debugPrint('Delete Error: $e');
      rethrow;
    }
  }

  DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  List<TransactionModel> _filterByRange(DateTimeRange? range) {
    if (range == null) return _all;
    final end = _endOfDay(range.end);
    return _all
        .where(
            (txn) => !txn.date.isBefore(range.start) && !txn.date.isAfter(end))
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

  List<TransactionModel> filterTransactions({
    TransactionType? type,
    String? category,
    DateTimeRange? dateRange,
    String? query,
  }) {
    return _all.where((txn) {
      if (type != null && type != TransactionType.all && txn.type != type) {
        return false;
      }

      if (category != null && txn.category != category) {
        return false;
      }

      if (dateRange != null) {
        final end = _endOfDay(dateRange.end);
        if (txn.date.isBefore(dateRange.start) || txn.date.isAfter(end)) {
          return false;
        }
      }

      if (query != null && query.isNotEmpty) {
        final searchText =
            '${txn.title} ${txn.category} ${txn.note ?? ''}'.toLowerCase();
        if (!searchText.contains(query.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _clearData() {
    _all.clear();
    _totalIncome = 0.0;
    _totalExpense = 0.0;
    _todayCount = 0;
    _monthCount = 0;
    _lastDoc = null;
    _hasMore = true;
  }

  void _updateTransactionInMemory(TransactionModel updatedTxn) {
    final index = _all.indexWhere((t) => t.id == updatedTxn.id);
    if (index == -1) return;

    final old = _all[index];

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

    if (_isToday(old.date)) _todayCount = (_todayCount - 1).clamp(0, 1 << 31);
    if (_isThisMonth(old.date)) {
      _monthCount = (_monthCount - 1).clamp(0, 1 << 31);
    }
    if (_isToday(updatedTxn.date)) _todayCount++;
    if (_isThisMonth(updatedTxn.date)) {
      _monthCount++;
    }

    _all[index] = updatedTxn;
    notifyListeners();
  }
}
