import 'package:intl/intl.dart';

class CurrencyHelper {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
    locale: 'en_IN',
  );

  static final NumberFormat _currencyFormatterNoDecimal = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 0,
    locale: 'en_IN',
  );

  /// Format amount with ₹ symbol and 2 decimal places
  static String format(double amount) {
    return _currencyFormatter.format(amount);
  }

  /// Format amount with ₹ symbol without decimal places
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return _currencyFormatterNoDecimal.format(amount);
    }
  }

  /// Format amount without symbol (for internal calculations display)
  static String formatWithoutSymbol(double amount) {
    return NumberFormat('#,##0.00', 'en_IN').format(amount);
  }

  /// Format amount for display in signed format (+/-)
  static String formatSigned(double amount, String type) {
    final formatted = format(amount.abs());
    if (type == 'income') {
      return '+$formatted';
    } else {
      return '-$formatted';
    }
  }
}
