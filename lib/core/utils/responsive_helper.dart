import 'package:flutter/material.dart';

class ResponsiveHelper {
  // Screen size breakpoints
  static const double mobileBreakpoint = 768;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Check device types
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth >= mobileBreakpoint && screenWidth < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  // Get responsive values
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  // Get responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsive(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
      ),
      vertical: responsive(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );
  }

  // Get responsive spacing
  static double getSpacing(BuildContext context, {double scale = 1.0}) {
    return responsive(
      context,
      mobile: 16.0 * scale,
      tablet: 20.0 * scale,
      desktop: 24.0 * scale,
    );
  }

  // Get responsive font size
  static double getFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    
    if (screenWidth > desktopBreakpoint) {
      return baseFontSize * 1.2;
    } else if (screenWidth > tabletBreakpoint) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize;
    }
  }

  // Get content max width for centering on large screens
  static double getContentMaxWidth(BuildContext context) {
    return responsive(
      context,
      mobile: double.infinity,
      tablet: 800,
      desktop: 1200,
    );
  }

  // Helper for wrapping content with max width
  static Widget constrainWidth(BuildContext context, Widget child) {
    final maxWidth = getContentMaxWidth(context);
    if (maxWidth == double.infinity) return child;
    
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// A more efficient replacement for Container when only decoration is needed
class AppDecoratedBox extends StatelessWidget {
  final Decoration decoration;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const AppDecoratedBox({
    super.key,
    required this.decoration,
    this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = child ?? const SizedBox.shrink();

    if (padding != null) {
      current = Padding(padding: padding!, child: current);
    }

    current = DecoratedBox(decoration: decoration, child: current);

    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    return current;
  }
}

// Lightweight colored container replacement
class ColoredContainer extends StatelessWidget {
  final Widget? child;
  final Color color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ColoredContainer({
    super.key,
    this.child,
    required this.color,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = ColoredBox(
      color: color,
      child: Padding(
        padding: padding ?? EdgeInsets.zero,
          child: child ?? const SizedBox.shrink()
      ),
    );

    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    return current;
  }
}

// Responsive card widget
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.color,
    this.elevation,
    this.borderRadius,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(
      ResponsiveHelper.responsive(
        context,
        mobile: 12.0,
        tablet: 16.0,
        desktop: 20.0,
      ),
    );

    final cardPadding = padding ?? EdgeInsets.all(
      ResponsiveHelper.responsive(
        context,
        mobile: 16.0,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );

    return Card(
      color: color ?? Colors.white,
      elevation: elevation ?? 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? defaultBorderRadius,
      ),
      margin: margin,
      child: Padding(
        padding: cardPadding,
        child: child,
      ),
    );
  }
}
