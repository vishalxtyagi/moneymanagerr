import 'package:flutter/material.dart';
import 'package:moneymanager/constants/constants.dart';
import 'package:moneymanager/utils/responsive_helper.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBorderRadius = BorderRadius.circular(
      ResponsiveHelper.responsive(
        context,
        mobile: AppConstants.defaultBorderRadius,
        tablet: 16.0,
        desktop: 20.0,
      ),
    );

    final cardPadding = padding ?? EdgeInsets.all(
      ResponsiveHelper.responsive(
        context,
        mobile: AppConstants.defaultPadding,
        tablet: 20.0,
        desktop: 24.0,
      ),
    );

    Widget cardChild = Card(
      color: color ?? AppColors.card,
      elevation: elevation ?? AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? defaultBorderRadius,
      ),
      margin: margin,
      child: Padding(
        padding: cardPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      cardChild = InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? defaultBorderRadius,
        child: cardChild,
      );
    }

    return cardChild;
  }
}
