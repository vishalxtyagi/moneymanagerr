import 'package:flutter/material.dart';
import 'package:moneymanager/core/constants/colors.dart';
import 'package:moneymanager/core/constants/styles.dart';
import 'package:moneymanager/core/utils/responsive_helper.dart';

class StatisticCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatisticCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          ResponsiveHelper.responsive(
            context,
            mobile: 16.0,
            tablet: 20.0,
            desktop: 24.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: ResponsiveHelper.responsive(
                context,
                mobile: 16.0,
                tablet: 18.0,
                desktop: 20.0,
              ),
              backgroundColor: color.withOpacity(0.1),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveHelper.responsive(
                  context,
                  mobile: 16.0,
                  tablet: 18.0,
                  desktop: 20.0,
                ),
              ),
            ),
            SizedBox(height: ResponsiveHelper.getSpacing(context, scale: 0.5)),
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: ResponsiveHelper.getFontSize(context, 12),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
