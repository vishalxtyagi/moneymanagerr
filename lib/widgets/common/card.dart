import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/utils/responsive_util.dart';

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
    final responsive = ResponsiveUtil.of(context);
    final radius =
        borderRadius ?? BorderRadius.circular(responsive.spacing(scale: 0.8));
    final contentPadding = padding ?? responsive.screenPadding();

    final cardContent = Card(
      color: color ?? AppColors.card,
      elevation: elevation ?? AppStyles.elevation,
      margin: margin,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: Padding(padding: contentPadding, child: child),
    );

    return onTap == null
        ? cardContent
        : Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: cardContent,
            ),
          );
  }
}
