import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/constants/enums.dart';
import 'package:moneymanager/utils/currency_util.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static const _mainChannel = 'financial_alerts';
  static const _persistentChannel = 'financial_assistant';
  static const _expenseAction = 'QUICK_EXPENSE';
  static const _balanceAction = 'VIEW_BALANCE';
  static const _persistentId = 100;

  static final _instance = NotificationService._();
  static final _notifications = AwesomeNotifications();
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  factory NotificationService() => _instance;
  NotificationService._();

  static bool _initialized = false;
  static bool _hasPermission = false;
  StreamSubscription<User?>? _authSub;

  static bool get isReady => _initialized && _hasPermission;

  Future<bool> initialize() async {
    if (_initialized) return _hasPermission;

    try {
      final success = await _notifications.initialize(
        'resource://drawable/app_icon',
        [
          NotificationChannel(
            channelKey: _mainChannel,
            channelName: 'Financial Alerts',
            channelDescription: 'Financial notifications',
            defaultColor: AppColors.primary,
            importance: NotificationImportance.Max,
            channelShowBadge: true,
          ),
          NotificationChannel(
            channelKey: _persistentChannel,
            channelName: 'Financial Assistant',
            channelDescription: 'Quick actions',
            defaultColor: AppColors.primary,
            importance: NotificationImportance.Default,
            locked: true,
            playSound: false,
            enableVibration: false,
          ),
        ],
        debug: kDebugMode,
      );

      if (success) {
        _hasPermission = await _notifications.isNotificationAllowed() ||
            await _notifications.requestPermissionToSendNotifications();

        _notifications.setListeners(
          onActionReceivedMethod: _handleAction,
          onDismissActionReceivedMethod: _onDismiss,
        );

        _authSub = _auth.authStateChanges().listen((user) {
          user != null ? _showPersistent() : _hidePersistent();
        });
      }

      return _initialized = success;
    } catch (e) {
      debugPrint('Notification init failed: $e');
      return false;
    }
  }

  Future<void> _showPersistent() async {
    if (!_hasPermission) return;

    try {
      await _notifications.createNotification(
        content: NotificationContent(
          id: _persistentId,
          channelKey: _persistentChannel,
          title: '💰 Money Manager',
          body: 'Tap below for quick actions — Add Expense or View Balance.',
          category: NotificationCategory.Service,
          actionType: ActionType.KeepOnTop,
          autoDismissible: false,
          locked: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: _expenseAction,
            label: 'Add Expense',
            requireInputText: true,
            actionType: ActionType.SilentAction,
          ),
          NotificationActionButton(
            key: _balanceAction,
            label: 'View Balance',
            autoDismissible: false,
            actionType: ActionType.SilentAction,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Show persistent failed: $e');
    }
  }

  Future<void> _hidePersistent() async {
    try {
      await _notifications.cancel(_persistentId);
    } catch (e) {
      debugPrint('Hide persistent failed: $e');
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _handleAction(ReceivedAction action) async {
    final user = _auth.currentUser;
    if (user == null) {
      return _notify(
          '🔐 Sign In Required', 'Please open Money Manager to continue.');
    }

    try {
      switch (action.buttonKeyPressed) {
        case _expenseAction:
          await _addExpense(user.uid, action.buttonKeyInput);
          break;
        case _balanceAction:
          await _showBalance(user.uid);
          break;
      }
    } catch (e) {
      await _notify(
          '❌ Action Failed', 'Something went wrong. Please try again.');
      debugPrint('Action error: $e');
    }
  }

  static Future<void> _addExpense(String userId, String input) async {
    final amount = double.tryParse(input.trim());

    if (input.trim().isEmpty) {
      return _notify('⚠️ No Amount Entered', 'Please enter an expense amount.');
    }
    if (amount == null || amount <= 0) {
      return _notify(
          '⚠️ Invalid Amount', 'Enter a valid number like 250 or 99.50.');
    }
    if (amount > 999999) {
      return _notify(
          '💸 Whoa, That’s Big!', 'Please enter a reasonable amount.');
    }

    // Ensure Firestore doc.id matches our generated id to keep models consistent
    final id = const Uuid().v4();
    await _firestore.collection('transactions').doc(id).set({
      'id': id,
      'userId': userId,
      'title': 'Quick Entry',
      'amount': amount,
      'date': Timestamp.now(),
      'category': 'Quick Expense',
      'type': TransactionType.expense.name,
      'note': 'Added via notification',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await _notify('✅ Expense Logged',
        '${CurrencyUtil.format(amount)} added successfully.');
  }

  static Future<void> _showBalance(String userId) async {
    final snapshot = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .get();

    double balance = 0.0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      final type = data['type'] as String?;

      if (type == TransactionType.income.name) {
        balance += amount;
      } else if (type == TransactionType.expense.name) {
        balance -= amount;
      }
    }

    await _notify('Current Balance',
        'You have ${CurrencyUtil.format(balance)} available.');
  }

  static Future<void> _notify(String title, String body) async {
    try {
      await _notifications.createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          channelKey: _mainChannel,
          title: title,
          body: body,
          autoDismissible: true,
        ),
      );
    } catch (e) {
      debugPrint('Notify failed: $e');
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _onDismiss(ReceivedAction action) async {
    if (action.id == _persistentId) {
      await _instance._showPersistent();
    }
  }

  // Public API
  static Future<void> showBalanceWarning(
      double balance, double threshold) async {
    if (isReady && balance <= threshold) {
      await _notify('⚠️ Low Balance Alert',
          'Your balance is down to ${CurrencyUtil.format(balance)}.');
    }
  }

  static Future<void> showExpenseAlert(double amount, double threshold) async {
    if (isReady && amount >= threshold) {
      await _notify('📉 Large Expense Alert',
          'You just spent ${CurrencyUtil.format(amount)}.');
    }
  }

  Future<void> showCustomNotification(String title, String body) async {
    if (isReady) await _notify(title, body);
  }

  void dispose() => _authSub?.cancel();
}
