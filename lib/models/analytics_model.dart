import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/models/transaction_model.dart';
import 'package:moneymanager/providers/transaction_provider.dart';

class AnalyticsModel {
  final double balance;
  final double income;
  final double expense;
  final ConsumptionData consumptionData;
  final Map<String, double> categoryExpenses;
  final List<TimeSeriesItem> timeSeriesData;

  AnalyticsModel({
    required this.balance,
    required this.income,
    required this.expense,
    required this.consumptionData,
    required this.categoryExpenses,
    required this.timeSeriesData,
  });

  factory AnalyticsModel.from(
      TransactionProvider provider, DateTimeRange? range) {
    final income = provider.getTotalIncome(range: range);
    final expense = provider.getTotalExpense(range: range);
    return AnalyticsModel(
      balance: provider.getBalance(range: range),
      income: income,
      expense: expense,
      consumptionData: _getConsumptionData(income, expense),
      categoryExpenses: provider.getExpensesByCategory(range: range),
      timeSeriesData: _getTimeSeriesData(provider.all, range),
    );
  }

  // Lightweight: totals only
  factory AnalyticsModel.fromTotals({
    required double income,
    required double expense,
  }) {
    final balance = income - expense;
    return AnalyticsModel(
      balance: balance,
      income: income,
      expense: expense,
      consumptionData: _getConsumptionData(income, expense),
      categoryExpenses: const {},
      timeSeriesData: const [],
    );
  }

  static ConsumptionData _getConsumptionData(double income, double expense) {
    if (income == 0) {
      return ConsumptionData(
        text: 'No income',
        color: AppColors.secondary,
        percentage: 0,
      );
    }

    final percentage = (expense / income) * 100;
    final isOver = percentage > 100;

    return ConsumptionData(
      text: isOver
          ? '${(percentage - 100).toStringAsFixed(0)}% over budget!'
          : '${percentage.toStringAsFixed(0)}% spent',
      color: isOver ? AppColors.error : AppColors.primaryVariant,
      percentage: percentage,
    );
  }

  static List<TimeSeriesItem> _getTimeSeriesData(
    List<TransactionModel> transactions,
    DateTimeRange? range,
  ) {
    if (range == null) return [];

    final start = range.start;
    final end = range.end;
    final diffDays = end.difference(start).inDays + 1;

    List<TimeSeriesItem> data = [];

    if (diffDays <= 7) {
      // Day-wise
      for (int i = 0; i < diffDays; i++) {
        final date = start.add(Duration(days: i));
        double income = 0;
        double expense = 0;

        for (var tx in transactions) {
          if (tx.date.year == date.year &&
              tx.date.month == date.month &&
              tx.date.day == date.day) {
            if (tx.type == TransactionType.income) {
              income += tx.amount;
            } else if (tx.type == TransactionType.expense) {
              expense += tx.amount;
            }
          }
        }

        data.add(TimeSeriesItem(
          label: DateFormat('MMM d').format(date),
          income: income,
          expense: expense,
        ));
      }
    } else if (diffDays <= 35) {
      // Week-wise
      final weekStart = start.subtract(Duration(days: start.weekday - 1));
      final weeks = ((end.difference(weekStart).inDays) / 7).ceil();

      for (int i = 0; i < weeks; i++) {
        final startWeek = weekStart.add(Duration(days: i * 7));
        final endWeek = startWeek.add(const Duration(days: 6));
        double income = 0;
        double expense = 0;

        for (var tx in transactions) {
          if (!tx.date.isBefore(startWeek) && !tx.date.isAfter(endWeek)) {
            if (tx.type == TransactionType.income) {
              income += tx.amount;
            } else if (tx.type == TransactionType.expense) {
              expense += tx.amount;
            }
          }
        }

        data.add(TimeSeriesItem(
          label: 'W${i + 1}',
          income: income,
          expense: expense,
        ));
      }
    } else {
      // Month-wise
      final monthStart = DateTime(start.year, start.month);
      final months = (end.year - start.year) * 12 + end.month - start.month + 1;

      for (int i = 0; i < months; i++) {
        final month = DateTime(monthStart.year, monthStart.month + i);
        double income = 0;
        double expense = 0;

        for (var tx in transactions) {
          if (tx.date.year == month.year && tx.date.month == month.month) {
            if (tx.type == TransactionType.income) {
              income += tx.amount;
            } else if (tx.type == TransactionType.expense) {
              expense += tx.amount;
            }
          }
        }

        data.add(TimeSeriesItem(
          label: DateFormat('MMM yy').format(month),
          income: income,
          expense: expense,
        ));
      }
    }

    return data;
  }
}

class TimeSeriesItem {
  final String label; // e.g., "Jul 1", "Jul 2"
  final double income;
  final double expense;

  TimeSeriesItem(
      {required this.label, required this.income, required this.expense});
}

class ConsumptionData {
  final String text;
  final Color color;
  final double percentage;

  ConsumptionData({
    required this.text,
    required this.color,
    required this.percentage,
  });
}
