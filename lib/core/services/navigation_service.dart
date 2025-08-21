import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router/app_router.dart';
import '../models/transaction_model.dart';

class NavigationService {
  static void goToDashboard(BuildContext context) {
    context.go(AppRouter.dashboard);
  }
  
  static void goToAnalytics(BuildContext context) {
    context.go(AppRouter.analytics);
  }
  
  static void goToCalendar(BuildContext context) {
    context.go(AppRouter.calendar);
  }
  
  static void goToSettings(BuildContext context) {
    context.go(AppRouter.settings);
  }
  
  static void goToAddTransaction(BuildContext context, {VoidCallback? onClose}) {
    context.push(AppRouter.addTransaction, extra: {
      'onClose': onClose,
    });
  }
  
  static void goToEditTransaction(
    BuildContext context, 
    TransactionModel transaction, {
    VoidCallback? onClose,
  }) {
    context.push(AppRouter.editTransaction, extra: {
      'transaction': transaction,
      'onClose': onClose,
    });
  }
  
  static void goToTransactionHistory(
    BuildContext context, {
    DateTimeRange? initialRange,
    String? initialCategory,
    bool ephemeralFilters = false,
  }) {
    context.push(AppRouter.transactionHistory, extra: {
      'initialRange': initialRange,
      'initialCategory': initialCategory,
      'ephemeralFilters': ephemeralFilters,
    });
  }
  
  static void goToCategoryManager(BuildContext context) {
    context.push(AppRouter.categoryManager);
  }
  
  static void goBack(BuildContext context) {
    context.pop();
  }
}
