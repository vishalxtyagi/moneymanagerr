import 'dart:async';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/enums.dart';
import 'package:moneymanager/core/utils/currency_util.dart';
import 'package:uuid/uuid.dart';

class NotificationService {
  static final AwesomeNotifications _notifications = AwesomeNotifications();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _mainChannelKey = 'financial_alerts';
  static const String _persistentChannelKey = 'financial_assistant';
  static const String _quickExpenseAction = 'QUICK_EXPENSE';
  static const String _viewBalanceAction = 'VIEW_BALANCE';
  static const int _persistentNotificationId = 100;

  static NotificationService? _instance;
  NotificationService._();
  factory NotificationService.getInstance() => _instance ??= NotificationService._();

  bool _isInitialized = false;
  bool _isPermissionGranted = false;
  StreamSubscription<User?>? _authSubscription;

  bool get isInitialized => _isInitialized;
  bool get isPermissionGranted => _isPermissionGranted;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final success = await _notifications.initialize(
        'resource://drawable/app_icon',
        [
          NotificationChannel(
            channelKey: _mainChannelKey,
            channelName: 'Financial Alerts',
            channelDescription: 'Financial notifications and feedback',
            defaultColor: AppColors.primary,
            importance: NotificationImportance.High,
          ),
          NotificationChannel(
            channelKey: _persistentChannelKey,
            channelName: 'Financial Assistant',
            channelDescription: 'Quick financial actions',
            defaultColor: AppColors.primary,
            importance: NotificationImportance.Default,
            locked: true,
            playSound: false,
            enableVibration: false,
          ),
        ],
        debug: kDebugMode,
      );

      if (!success) return false;

      _isPermissionGranted = await _notifications.isNotificationAllowed() ||
          await _notifications.requestPermissionToSendNotifications();

      _notifications.setListeners(
        onActionReceivedMethod: _handleNotificationAction,
        onDismissActionReceivedMethod: _onNotificationDismissed,
      );

      _setupAuthListener();
      _isInitialized = true;
      return true;
    } catch (e) {
      debugPrint('NotificationService initialization failed: $e');
      return false;
    }
  }

  void _setupAuthListener() {
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        _showPersistentNotification();
      } else {
        _hidePersistentNotification();
      }
    });
  }

  Future<void> _showPersistentNotification() async {
    if (!_isPermissionGranted) return;

    try {
      await _notifications.createNotification(
        content: NotificationContent(
          id: _persistentNotificationId,
          channelKey: _persistentChannelKey,
          title: '💰 Money Manager',
          body: 'Quick financial actions at your fingertips',
          category: NotificationCategory.Service,
          actionType: ActionType.KeepOnTop,
          autoDismissible: false,
          locked: true,
        ),
        actionButtons: [
          NotificationActionButton(
            key: _quickExpenseAction,
            label: 'Add Expense',
            requireInputText: true,
            actionType: ActionType.SilentAction,
          ),
          NotificationActionButton(
            key: _viewBalanceAction,
            label: 'View Balance',
            actionType: ActionType.SilentAction,
          ),
        ],
      );
    } catch (e) {
      debugPrint('Failed to show persistent notification: $e');
    }
  }

  Future<void> _hidePersistentNotification() async {
    try {
      await _notifications.cancel(_persistentNotificationId);
    } catch (e) {
      debugPrint('Failed to hide persistent notification: $e');
    }
  }

  @pragma("vm:entry-point")
  static Future<void> _handleNotificationAction(ReceivedAction action) async {
    final user = _auth.currentUser;
    if (user == null) {
      return _showNotification('🔐 Sign In Required', 'Please open the app to sign in');
    }

    try {
      switch (action.buttonKeyPressed) {
        case _quickExpenseAction:
          await _processQuickExpense(user.uid, action.buttonKeyInput);
          break;
        case _viewBalanceAction:
          await _processViewBalance(user.uid);
          break;
      }
    } catch (e) {
      await _showNotification('❌ Error', 'Action failed. Please try again.');
      debugPrint('Notification action error: $e');
    }
  }

  static Future<void> _processQuickExpense(String userId, String input) async {
    final cleanInput = input.trim();

    if (cleanInput.isEmpty) {
      return _showNotification('⚠️ Empty Input', 'Please enter an amount');
    }

    final amount = double.tryParse(cleanInput);
    if (amount == null || amount <= 0) {
      return _showNotification('⚠️ Invalid Amount', 'Enter a valid positive number');
    }

    if (amount > 999999) {
      return _showNotification('⚠️ Amount Too Large', 'Enter a reasonable amount');
    }

    await _firestore.collection('transactions').add({
      'id': const Uuid().v4(),
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

    await _showNotification('✅ Expense Added', '${CurrencyUtil.format(amount)} logged successfully!');
  }

  static Future<void> _processViewBalance(String userId) async {
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

    // Enhanced balance display with status
    String emoji = '💰';
    String status = '';
    
    if (balance < 0) {
      emoji = '⚠️';
      status = ' (Deficit)';
    } else if (balance > 10000) {
      emoji = '💎';
      status = ' (Excellent)';
    } else if (balance > 1000) {
      emoji = '💚';
      status = ' (Good)';
    } else if (balance < 100) {
      emoji = '🟡';
      status = ' (Low)';
    }

    await _showNotification('$emoji Current Balance', '${CurrencyUtil.format(balance)}$status');
  }

  static Future<void> _showNotification(String title, String body) async {
    try {
      await _notifications.createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch % 100000,
          channelKey: _mainChannelKey,
          title: title,
          body: body,
          autoDismissible: true,
        ),
      );
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  // Public methods for app usage
  Future<void> showBalanceWarning(double balance, double threshold) async {
    if (!_isPermissionGranted || balance > threshold) return;
    await _showNotification('⚠️ Low Balance Alert', 'Balance: ${CurrencyUtil.format(balance)}');
  }

  Future<void> showExpenseAlert(double amount, double threshold) async {
    if (!_isPermissionGranted || amount < threshold) return;
    await _showNotification('📉 Large Expense Alert', 'You spent ${CurrencyUtil.format(amount)}');
  }

  Future<void> showCustomNotification(String title, String body) async {
    if (!_isPermissionGranted) return;
    await _showNotification(title, body);
  }

  @pragma("vm:entry-point")
  static Future<void> _onNotificationDismissed(ReceivedAction action) async {
    if (action.id == _persistentNotificationId) {
      final instance = NotificationService.getInstance();
      await instance._showPersistentNotification();
    }
  }

  void dispose() {
    _authSubscription?.cancel();
  }
}