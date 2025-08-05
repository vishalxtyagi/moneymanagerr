import 'dart:developer';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:moneymanager/constants/app_colors.dart';
import 'package:moneymanager/utils/currency_helper.dart';

class NotificationService {

  Future<void> initialize() async {
    await AwesomeNotifications().initialize(
      'resource://drawable/app_icon',
      [
        NotificationChannel(
          channelGroupKey: 'money_manager_group',
          channelKey: 'money_manager_channel',
          channelName: 'Money Manager Notifications',
          channelDescription: 'Notifications for Money Manager app',
          defaultColor: AppColors.primary,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          onlyAlertOnce: false,
          playSound: true,
          criticalAlerts: false,
        ),
      ],
      // Channel groups are optional
      channelGroups: [
        NotificationChannelGroup(
          channelGroupKey: 'money_manager_group',
          channelGroupName: 'Money Manager Group'
        ),
      ],
      debug: true,
    );

    // Request notification permissions
    await _requestNotificationPermissions();
  }

  Future<void> _requestNotificationPermissions() async {
    // Check if notifications are allowed
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();

    if (!isAllowed) {
      // Request permission
      await AwesomeNotifications().requestPermissionToSendNotifications();
    }

  }

  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id ?? DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'money_manager_channel',
        actionType: ActionType.Default,
        title: title,
        body: body,
        showWhen: false,
        wakeUpScreen: true,
        category: NotificationCategory.Reminder,
      ),
    );
  }

  Future<void> showBreakEvenNotification({
    required double currentBalance,
    required double threshold,
  }) async {
    if (currentBalance > 0 && currentBalance <= threshold) {
      await showNotification(
        title: 'Low Balance Alert!',
        body: 'Your balance is ${CurrencyHelper.format(currentBalance)}. You\'re approaching break-even.',
        id: 1, // Use a specific ID for break-even notifications
      );
    }
  }

  Future<void> showLargeExpenseNotification({
    required double amount,
    required double threshold,
  }) async {
    if (amount >= threshold) {
      log('Large expense notification triggered');
      await showNotification(
        title: 'Large Expense Alert!',
        body: 'You just spent ${CurrencyHelper.format(amount)}. This is above your threshold.',
        id: 2, // Use a specific ID for large expense notifications
      );
    }
  }

}