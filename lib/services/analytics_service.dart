import 'package:flutter/material.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/transaction_model.dart';

class AnalyticsData {
  final double balance;
  final double income;
  final double expense;
  final Map<String, double> expensesByCategory;
  final List<Map<String, dynamic>> timeSeriesData;

  const AnalyticsData({
    required this.balance,
    required this.income,
    required this.expense,
    required this.expensesByCategory,
    required this.timeSeriesData,
  });
}

class DateRangeOption {
  final String label;
  final DateTimeRange range;

  const DateRangeOption({
    required this.label,
    required this.range,
  });
}

class AnalyticsService {
  static List<DateRangeOption> getQuickDateRanges() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfYear = DateTime(now.year, 1, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);

    return [
      DateRangeOption(
        label: 'This Month',
        range: DateTimeRange(start: startOfMonth, end: now),
      ),
      DateRangeOption(
        label: 'Last Month',
        range: DateTimeRange(start: lastMonthStart, end: lastMonthEnd),
      ),
      DateRangeOption(
        label: 'This Year',
        range: DateTimeRange(start: startOfYear, end: now),
      ),
    ];
  }

  static AnalyticsData calculateAnalytics(
    List<TransactionModel> transactions,
    DateTimeRange? dateRange,
  ) {
    final filteredTransactions = dateRange != null
        ? _filterByDateRange(transactions, dateRange)
        : transactions;

    final income = _calculateTotalIncome(filteredTransactions);
    final expense = _calculateTotalExpense(filteredTransactions);
    final balance = income - expense;
    final expensesByCategory = _getExpensesByCategory(filteredTransactions);
    final timeSeriesData = _getTimeSeriesData(filteredTransactions, dateRange);

    return AnalyticsData(
      balance: balance,
      income: income,
      expense: expense,
      expensesByCategory: expensesByCategory,
      timeSeriesData: timeSeriesData,
    );
  }

  static List<TransactionModel> _filterByDateRange(
    List<TransactionModel> transactions,
    DateTimeRange range,
  ) {
    final endOfDay = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );

    return transactions.where((txn) {
      return !txn.date.isBefore(range.start) && !txn.date.isAfter(endOfDay);
    }).toList();
  }

  static double _calculateTotalIncome(List<TransactionModel> transactions) {
    return transactions
        .where((txn) => txn.type == TransactionType.income)
        .fold(0.0, (total, txn) => total + txn.amount);
  }

  static double _calculateTotalExpense(List<TransactionModel> transactions) {
    return transactions
        .where((txn) => txn.type == TransactionType.expense)
        .fold(0.0, (total, txn) => total + txn.amount);
  }

  static Map<String, double> _getExpensesByCategory(
    List<TransactionModel> transactions,
  ) {
    final expenses = <String, double>{};

    for (final txn in transactions) {
      if (txn.type == TransactionType.expense) {
        expenses[txn.category] = (expenses[txn.category] ?? 0) + txn.amount;
      }
    }

    final sortedEntries = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  static List<Map<String, dynamic>> _getTimeSeriesData(
    List<TransactionModel> transactions,
    DateTimeRange? dateRange,
  ) {
    if (transactions.isEmpty) return [];

    final now = DateTime.now();
    final range = dateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );

    final dataPoints = <DateTime, double>{};
    final daysDiff = range.end.difference(range.start).inDays;

    if (daysDiff <= 31) {
      for (int i = 0; i <= daysDiff; i++) {
        final date = range.start.add(Duration(days: i));
        dataPoints[DateTime(date.year, date.month, date.day)] = 0.0;
      }
    } else {
      for (int month = range.start.month; month <= range.end.month; month++) {
        final date = DateTime(range.start.year, month, 1);
        dataPoints[date] = 0.0;
      }
    }

    for (final txn in transactions) {
      if (txn.type == TransactionType.expense) {
        final key = daysDiff <= 31
            ? DateTime(txn.date.year, txn.date.month, txn.date.day)
            : DateTime(txn.date.year, txn.date.month, 1);

        if (dataPoints.containsKey(key)) {
          dataPoints[key] = dataPoints[key]! + txn.amount;
        }
      }
    }

    return dataPoints.entries
        .map((entry) => {
              'date': entry.key,
              'amount': entry.value,
            })
        .toList()
      ..sort(
          (a, b) => (a['date']! as DateTime).compareTo(b['date']! as DateTime));
  }
}
