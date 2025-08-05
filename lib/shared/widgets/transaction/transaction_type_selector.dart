import 'package:flutter/material.dart';
import 'package:moneymanager/constants/constants.dart';

class TransactionTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTypeButton(
              context,
              'expense',
              'Expense',
              Icons.arrow_downward,
              AppColors.expense,
              selectedType == 'expense',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTypeButton(
              context,
              'income',
              'Income',
              Icons.arrow_upward,
              AppColors.income,
              selectedType == 'income',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeButton(
    BuildContext context,
    String type,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onTypeChanged(type),
      child: AnimatedContainer(
        duration: AppConstants.shortAnimation,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
