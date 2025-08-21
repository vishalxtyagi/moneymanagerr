import 'package:flutter/material.dart';

/// Mixin to optimize provider rebuilds by limiting notifications
mixin NotifierMixin on ChangeNotifier {
  bool _isNotifying = false;
  bool _hasScheduledNotification = false;

  /// Batches multiple updates into a single notification
  void batchUpdate(VoidCallback updates) {
    if (_isNotifying) return;

    _isNotifying = true;
    try {
      updates();
    } finally {
      _isNotifying = false;
    }

    _scheduleNotification();
  }

  void _scheduleNotification() {
    if (_hasScheduledNotification) return;

    _hasScheduledNotification = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasScheduledNotification = false;
      notifyListeners();
    });
  }

  @override
  void notifyListeners() {
    if (_isNotifying) return;
    super.notifyListeners();
  }
}

class CachedValueNotifier<T> extends ValueNotifier<T> {
  CachedValueNotifier(super.value);

  @override
  set value(T newValue) {
    if (value != newValue) {
      super.value = newValue;
    }
  }
}
