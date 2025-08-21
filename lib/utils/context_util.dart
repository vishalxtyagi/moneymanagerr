import 'package:flutter/material.dart';
import 'package:moneymanager/constants/styles.dart';

enum DeviceType { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  // Cache MediaQuery result to avoid repeated calls
  Size get _screenSize => MediaQuery.sizeOf(this);

  // Device type with cached width
  DeviceType get deviceType {
    final width = _screenSize.width;
    if (width < AppStyles.mobile) return DeviceType.mobile;
    if (width < AppStyles.tablet) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Convenience flags
  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;

  // Generic responsive value
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  // Common layout helpers
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
        horizontal: responsiveValue(mobile: 16.0, tablet: 24.0, desktop: 32.0),
        vertical: responsiveValue(mobile: 16.0, tablet: 20.0, desktop: 24.0),
      );

  double spacing([double scale = 1]) =>
      responsiveValue(mobile: 16.0, tablet: 20.0, desktop: 24.0) * scale;

  double fontSize(double base) =>
      base * responsiveValue(mobile: 1.0, tablet: 1.1, desktop: 1.2);

  double get contentMaxWidth =>
      responsiveValue(mobile: double.infinity, tablet: 800.0, desktop: 1200.0);

  Widget constrain(Widget child) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth:
                contentMaxWidth == double.infinity ? double.maxFinite : contentMaxWidth,
          ),
          child: child,
        ),
      );
}

extension AppThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);

  bool get isDarkMode => theme.brightness == Brightness.dark;

  ColorScheme get colors => theme.colorScheme;

  TextTheme get textTheme => theme.textTheme;
}
