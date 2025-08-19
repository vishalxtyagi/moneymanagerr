import 'package:flutter/material.dart';

/// Optimized alternatives to Container misuse for better performance

/// Use instead of Container when only padding is needed
class AppPadding extends StatelessWidget {
  final EdgeInsetsGeometry padding;
  final Widget child;

  const AppPadding({
    super.key,
    required this.padding,
    required this.child,
  });

  AppPadding.all(
    double value, {
    super.key,
    required this.child,
  }) : padding = EdgeInsets.all(value);

  AppPadding.symmetric({
    super.key,
    double horizontal = 0.0,
    double vertical = 0.0,
    required this.child,
  }) : padding = EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

  AppPadding.only({
    super.key,
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
    required this.child,
  }) : padding = EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);

  @override
  Widget build(BuildContext context) {
    return Padding(padding: padding, child: child);
  }
}

/// Use instead of Container when only decoration is needed
class AppDecoratedBox extends StatelessWidget {
  final Decoration decoration;
  final Widget child;
  final DecorationPosition position;

  const AppDecoratedBox({
    super.key,
    required this.decoration,
    required this.child,
    this.position = DecorationPosition.background,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: decoration,
      position: position,
      child: child,
    );
  }
}

/// Use instead of Container when only size constraints are needed
class AppSizedBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget? child;

  const AppSizedBox({
    super.key,
    this.width,
    this.height,
    this.child,
  });

  const AppSizedBox.square(
    double dimension, {
    super.key,
    this.child,
  }) : width = dimension, height = dimension;

  const AppSizedBox.expand({
    super.key,
    this.child,
  }) : width = double.infinity, height = double.infinity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: child,
    );
  }
}

/// Optimized spacer widgets for consistent spacing
class AppSpacing {
  const AppSpacing._();

  // Vertical spacers
  static const Widget vertical4 = SizedBox(height: 4);
  static const Widget vertical8 = SizedBox(height: 8);
  static const Widget vertical12 = SizedBox(height: 12);
  static const Widget vertical16 = SizedBox(height: 16);
  static const Widget vertical20 = SizedBox(height: 20);
  static const Widget vertical24 = SizedBox(height: 24);
  static const Widget vertical32 = SizedBox(height: 32);

  // Horizontal spacers
  static const Widget horizontal4 = SizedBox(width: 4);
  static const Widget horizontal8 = SizedBox(width: 8);
  static const Widget horizontal12 = SizedBox(width: 12);
  static const Widget horizontal16 = SizedBox(width: 16);
  static const Widget horizontal20 = SizedBox(width: 20);
  static const Widget horizontal24 = SizedBox(width: 24);
  static const Widget horizontal32 = SizedBox(width: 32);

  // Dynamic spacers
  static Widget vertical(double height) => SizedBox(height: height);
  static Widget horizontal(double width) => SizedBox(width: width);
}

/// Optimized divider alternatives
class AppDividers {
  const AppDividers._();

  static const Widget thin = Divider(height: 1, thickness: 0.5);
  static const Widget normal = Divider(height: 1, thickness: 1);
  static const Widget thick = Divider(height: 2, thickness: 2);
  
  static const Widget verticalThin = VerticalDivider(width: 1, thickness: 0.5);
  static const Widget verticalNormal = VerticalDivider(width: 1, thickness: 1);
  static const Widget verticalThick = VerticalDivider(width: 2, thickness: 2);
}

/// Optimized layout helpers
class AppLayout {
  const AppLayout._();

  /// Centered content with optional constraints
  static Widget center({
    required Widget child,
    double? maxWidth,
    double? maxHeight,
  }) {
    Widget content = child;
    if (maxWidth != null || maxHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: content,
      );
    }
    return Center(child: content);
  }

  /// Responsive grid layout
  static Widget responsiveGrid({
    required List<Widget> children,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    double childAspectRatio = 1.0,
    bool shrinkWrap = false,
  }) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      children: children,
    );
  }

  /// Responsive row with proper spacing
  static Widget responsiveRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 0.0,
  }) {
    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1 && spacing > 0) {
        spacedChildren.add(SizedBox(width: spacing));
      }
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }

  /// Responsive column with proper spacing
  static Widget responsiveColumn({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    double spacing = 0.0,
  }) {
    final List<Widget> spacedChildren = [];
    for (int i = 0; i < children.length; i++) {
      spacedChildren.add(children[i]);
      if (i < children.length - 1 && spacing > 0) {
        spacedChildren.add(SizedBox(height: spacing));
      }
    }
    
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: spacedChildren,
    );
  }
}
