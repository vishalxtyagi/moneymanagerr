import 'package:flutter/material.dart';
import 'package:moneymanager/models/analytics_model.dart';
import 'package:moneymanager/providers/transaction_provider.dart';
import 'package:moneymanager/utils/notifier_utils.dart';

/// Centralized analytics computations to avoid expensive calculations in build methods
class AnalyticsProvider extends ChangeNotifier with NotifierMixin {
  final TransactionProvider _transactionProvider;
  
  AnalyticsModel? _analytics;
  DateTimeRange? _currentRange;
  
  AnalyticsProvider(this._transactionProvider) {
    _transactionProvider.addListener(_onTransactionsChanged);
  }

  AnalyticsModel? get analytics => _analytics;
  DateTimeRange? get currentRange => _currentRange;

  void _onTransactionsChanged() {
    if (_currentRange != null) {
      _recomputeAnalytics(_currentRange!);
    }
  }

  void updateDateRange(DateTimeRange range) {
    if (_currentRange != range) {
      _currentRange = range;
      _recomputeAnalytics(range);
    }
  }

  void _recomputeAnalytics(DateTimeRange range) {
    batchUpdate(() {
      _analytics = AnalyticsModel.from(_transactionProvider, range);
    });
  }

  @override
  void dispose() {
    _transactionProvider.removeListener(_onTransactionsChanged);
    super.dispose();
  }
}
