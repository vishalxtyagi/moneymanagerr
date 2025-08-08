import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/styles.dart';

class ResponsiveUtil {
  final double width;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;

  ResponsiveUtil._(this.width)
      : isMobile = width < AppStyles.mobile,
        isTablet = width >= AppStyles.mobile && width < AppStyles.tablet,
        isDesktop = width >= AppStyles.tablet;

  static ResponsiveUtil of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return ResponsiveUtil._(width);
  }

  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop) return desktop ?? tablet ?? mobile;
    if (isTablet) return tablet ?? mobile;
    return mobile;
  }

  EdgeInsets screenPadding() => EdgeInsets.symmetric(
        horizontal: value(mobile: 16, tablet: 24, desktop: 32),
        vertical: value(mobile: 16, tablet: 20, desktop: 24),
      );

  double spacing({double scale = 1}) =>
      value(mobile: 16, tablet: 20, desktop: 24) * scale;

  double fontSize(double base) =>
      base * value(mobile: 1.0, tablet: 1.1, desktop: 1.2);

  double contentMaxWidth() =>
      value(mobile: double.infinity, tablet: 800, desktop: 1200);

  Widget constrain(Widget child) {
    final maxWidth = contentMaxWidth();
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth == double.infinity ? double.maxFinite : maxWidth,
        ),
        child: child,
      ),
    );
  }
}
