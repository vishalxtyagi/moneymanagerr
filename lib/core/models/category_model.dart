import 'package:flutter/material.dart';
import 'package:moneymanager/core/utils/category_util.dart';

class CategoryModel {
  final String name;
  final int iconIdx;
  final bool isIncome;
  final Color color;

  const CategoryModel({
    required this.name,
    required this.iconIdx,
    required this.isIncome,
    required this.color,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'iconIndex': iconIdx,
        'isIncome': isIncome,
        'color': color.value,
      };

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      name: map['name'],
      iconIdx: map['iconIndex'] ?? CategoryUtil.defaultIconIndex,
      isIncome: map['isIncome'] ?? false,
      color: map['color'] != null
          ? Color(map['color'])
          : CategoryUtil.getRandomCategoryColor(),
    );
  }

  static CategoryModel withFallback({
    required String name,
    required bool isIncome,
    int? iconIdx,
  }) {
    return CategoryModel(
      name: name,
      iconIdx: iconIdx ?? CategoryUtil.defaultIconIndex,
      isIncome: isIncome,
      color: CategoryUtil.getRandomCategoryColor(),
    );
  }

  static final List<CategoryModel> defaultIncomeCategories = [
    withFallback(name: 'Salary', iconIdx: 26, isIncome: true),
    withFallback(name: 'Business', iconIdx: 23, isIncome: true),
    withFallback(name: 'Investments', iconIdx: 27, isIncome: true),
    withFallback(name: 'Freelancing', iconIdx: 24, isIncome: true),
    withFallback(name: 'Rental Income', iconIdx: 26, isIncome: true),
    withFallback(name: 'Bonus', iconIdx: 28, isIncome: true),
    withFallback(name: 'Gift Money', iconIdx: 28, isIncome: true),
    withFallback(name: 'Interest', iconIdx: 29, isIncome: true),
    withFallback(name: 'Other', iconIdx: 1, isIncome: true),
  ];

  static final List<CategoryModel> defaultExpenseCategories = [
    withFallback(name: 'Quick Expense', iconIdx: 0, isIncome: false),
    withFallback(name: 'Food & Dining', iconIdx: 2, isIncome: false),
    withFallback(name: 'Transportation', iconIdx: 4, isIncome: false),
    withFallback(name: 'Shopping & Entertainment', iconIdx: 8, isIncome: false),
    withFallback(name: 'Bills & Utilities', iconIdx: 11, isIncome: false),
    withFallback(name: 'Healthcare', iconIdx: 16, isIncome: false),
    withFallback(name: 'Education', iconIdx: 22, isIncome: false),
    withFallback(name: 'Travel', iconIdx: 7, isIncome: false),
    withFallback(name: 'Personal Care', iconIdx: 17, isIncome: false),
    withFallback(name: 'Groceries', iconIdx: 25, isIncome: false),
    withFallback(name: 'Fuel', iconIdx: 5, isIncome: false),
    withFallback(name: 'Other', iconIdx: 1, isIncome: false),
  ];
}
