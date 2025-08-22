import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/enums.dart';
import '../constants/router.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_drawer.dart';
import '../utils/context_util.dart';

class NavigationService {
  static void goToAddTransaction(BuildContext context,
      {VoidCallback? onClose}) {
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
    TransactionType? initialType,
    String? initialCategory,
    DateTimeRange? initialDateRange,
    String? initialQuery,
  }) {
    context.push(AppRouter.transactionHistory, extra: {
      'initialType': initialType,
      'initialCategory': initialCategory,
      'initialDateRange': initialDateRange,
      'initialQuery': initialQuery,
    });
  }

  /// Opens the transaction drawer for adding a new transaction
  static void openTransactionDrawer(BuildContext context) {
    final scaffoldState = Scaffold.of(context);
    scaffoldState.openEndDrawer();
  }

  /// Opens the transaction drawer for editing an existing transaction
  static void openEditTransactionDrawer(
    BuildContext context,
    TransactionModel transaction,
  ) {
    final transactionDrawer = TransactionDrawer(
      transaction: transaction,
      onClose: () => Navigator.of(context).pop(),
    );

    if (context.isDesktop) {
      showDialog(
        context: context,
        builder: (context) => transactionDrawer,
      );
    } else {
      showAdaptiveDialog(
        context: context,
        builder: (context) => transactionDrawer,
      );
    }
  }
}
