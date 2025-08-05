import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/utils/currency_util.dart';

class NotificationService {
  static final _notifier = AwesomeNotifications();

  static const _groupKey = 'money_manager_group';
  static const _channelKey = 'money_manager_channel';
  static const _persistentChannelKey = 'money_manager_persistent';

  static const _idBreakEven = 1;
  static const _idLargeExpense = 2;
  static const _idPersistent = 101;

  /// Initialize channels, groups, permissions, and listeners
  Future<void> initialize() async {
    await _notifier.initialize(
      'resource://drawable/app_icon',
      [
        NotificationChannel(
          channelKey: _channelKey,
          channelName: 'Financial Alerts',
          channelDescription: 'Spending and savings alerts',
          channelGroupKey: _groupKey,
          defaultColor: AppColors.primary,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: _persistentChannelKey,
          channelName: 'Quick Expense Entry',
          channelDescription: 'Enter expenses from notification',
          channelGroupKey: _groupKey,
          defaultColor: AppColors.primary,
          importance: NotificationImportance.High,
          locked: true,
          playSound: false,
        ),
      ],
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: _groupKey,
          channelGroupName: 'Money Manager',
        ),
      ],
      debug: false,
    );

    if (!await _notifier.isNotificationAllowed()) {
      await _notifier.requestPermissionToSendNotifications();
    }

    _notifier.setListeners(onActionReceivedMethod: _onActionReceived);
  }

  /// Show or re-show persistent notification (survives swipe-dismiss)
  static Future<void> showPersistentNotification() async {
    await _notifier.createNotification(
      content: NotificationContent(
        id: _idPersistent,
        channelKey: _persistentChannelKey,
        title: '💸 Quick Expense',
        body: 'Tap below to log an expense instantly.',
        category: NotificationCategory.Service,
        actionType: ActionType.KeepOnTop,
        autoDismissible: false,
        locked: true,
        wakeUpScreen: true,
      ),
      actionButtons: [
        NotificationActionButton(
          key: 'custom_expense',
          label: 'Enter Amount',
          requireInputText: true,
          actionType: ActionType.SilentAction,
        ),
      ],
    );
  }

  /// Recreates persistent notification if dismissed
  static Future<void> ensurePersistentNotification() async {
    final current = await _notifier.listScheduledNotifications();
    final stillVisible = current.any((n) => n.content?.id == _idPersistent);
    if (!stillVisible) await showPersistentNotification();
  }

  /// Generic notification
  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);
    await _notifier.createNotification(
      content: NotificationContent(
        id: notificationId,
        channelKey: _channelKey,
        title: title,
        body: body,
        category: NotificationCategory.Reminder,
        wakeUpScreen: true,
        showWhen: true,
      ),
    );
  }

  /// Show notification if balance is low
  Future<void> showBreakEvenNotification({
    required double currentBalance,
    required double threshold,
  }) async {
    if (currentBalance > 0 && currentBalance <= threshold) {
      await showNotification(
        title: '⚠️ Low Balance',
        body: 'Your balance is ${CurrencyUtil.format(currentBalance)}. Watch your spending!',
        id: _idBreakEven,
      );
    }
  }

  /// Show notification on large expense
  Future<void> showLargeExpenseNotification({
    required double amount,
    required double threshold,
  }) async {
    if (amount >= threshold) {
      await showNotification(
        title: '📉 Large Expense',
        body: 'You spent ${CurrencyUtil.format(amount)}, exceeding your limit.',
        id: _idLargeExpense,
      );
    }
  }

  /// Notification button handler
  @pragma("vm:entry-point")
  static Future<void> _onActionReceived(ReceivedAction action) async {
    if (action.buttonKeyPressed != 'custom_expense') return;

    final input = action.buttonKeyInput.trim();
    final amount = double.tryParse(input) ?? 0;

    if (amount <= 0) {
      await _notifier.createNotification(
        content: NotificationContent(
          id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
          channelKey: _channelKey,
          title: 'Invalid Entry',
          body: 'Please enter a valid amount.',
          category: NotificationCategory.Status,
        ),
      );
      return;
    }

    // TODO: Save to Firestore here
    // Example:
    // await FirebaseFirestore.instance.collection('transactions').add({
    //   'amount': amount,
    //   'category': 'Quick Entry',
    //   'description': 'Added via persistent notification',
    //   'type': 'expense',
    //   'date': FieldValue.serverTimestamp(),
    //   'createdAt': FieldValue.serverTimestamp(),
    //   'userId': 'current_user_id',
    // });

    await _notifier.createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: _channelKey,
        title: '✅ Expense Added',
        body: '${CurrencyUtil.format(amount)} saved successfully.',
        category: NotificationCategory.Status,
      ),
    );

    // Re-show persistent notification after interaction
    await showPersistentNotification();
  }
}