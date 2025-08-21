import 'package:flutter/material.dart';
import 'package:moneymanager/constants/colors.dart';
import 'package:moneymanager/utils/context_util.dart';

class InsightCard extends StatelessWidget {
  const InsightCard(
      {super.key,
      required this.title,
      required this.description,
      required this.color,
      required this.icon});

  final String title;
  final String description;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon, color: color, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: context.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        overflow: TextOverflow.ellipsis,
                        fontSize: context.fontSize(12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
